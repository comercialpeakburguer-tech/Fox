<?php

namespace App\Traits;

use App\CentralLogics\Helpers;

trait HasProductVideoPreview
{
    protected $supportedVideoProtocols = ['http', 'https'];

    protected function getVideoPlaceholderAssetUrl(): string
    {
        return asset('public/assets/admin/img/video-placeholder.svg');
    }

    public function getVideoFullUrlAttribute()
    {
        if (!$this->video) {
            return null;
        }

        $disk = Helpers::getStorageDiskByKey($this, 'video', 'public');

        if (Helpers::getStoredFileSize('product/', $this->video, $disk) <= 0) {
            return null;
        }

        return Helpers::get_full_url('product', $this->video, $disk, 'default');
    }

    public function getVideoSizeAttribute()
    {
        if (!$this->video) {
            return 0;
        }

        return Helpers::getStoredFileSize('product/', $this->video, Helpers::getStorageDiskByKey($this, 'video', 'public'));
    }

    public function getVideoPreviewTypeAttribute()
    {
        if ($this->video_full_url) {
            return 'upload';
        }

        $videoLink = $this->getResolvedVideoLink();
        if (!$videoLink) {
            return null;
        }

        if ($this->extractYoutubeVideoId($videoLink) || $this->extractVimeoVideoId($videoLink)) {
            return 'embed';
        }

        if ($this->isDirectVideoUrl($videoLink)) {
            return 'direct';
        }

        return 'unsupported';
    }

    public function getVideoEmbedUrlAttribute()
    {
        $videoLink = $this->getResolvedVideoLink();
        if (!$videoLink) {
            return null;
        }

        if ($youtubeId = $this->extractYoutubeVideoId($videoLink)) {
            return 'https://www.youtube.com/embed/' . $youtubeId . '?autoplay=1&rel=0';
        }

        if ($vimeoId = $this->extractVimeoVideoId($videoLink)) {
            return 'https://player.vimeo.com/video/' . $vimeoId . '?autoplay=1';
        }

        return null;
    }

    public function getVideoPreviewUrlAttribute()
    {
        if ($this->video_full_url) {
            return $this->video_full_url;
        }

        return $this->video_preview_type === 'direct' ? $this->getResolvedVideoLink() : null;
    }

    public function getVideoThumbnailUrlAttribute()
    {
        if ($this->video_link) {
            $videoLink = $this->getResolvedVideoLink();
            if ($videoLink && ($youtubeId = $this->extractYoutubeVideoId($videoLink))) {
                return 'https://img.youtube.com/vi/' . $youtubeId . '/hqdefault.jpg';
            }
        }

        return $this->getVideoPlaceholderAssetUrl();
    }

    public function getVideoPreviewModalTypeAttribute()
    {
        if (in_array($this->video_preview_type, ['upload', 'direct'], true)) {
            return 'video';
        }

        if ($this->video_preview_type === 'embed') {
            return 'embed';
        }

        return null;
    }

    public function getVideoPreviewModalUrlAttribute()
    {
        if ($this->video_preview_modal_type === 'video') {
            return $this->video_preview_url;
        }

        if ($this->video_preview_modal_type === 'embed') {
            return $this->video_embed_url;
        }

        return null;
    }

    public function getHasVideoPreviewAttribute(): bool
    {
        return (bool) ($this->video_preview_modal_type && ($this->video_preview_modal_url || $this->video_thumbnail_url || $this->video_full_url));
    }

    public function getHasVideoSourceAttribute(): bool
    {
        return (bool) ($this->video_full_url || $this->getRawResolvedVideoLink());
    }

    protected function getResolvedVideoLink(): ?string
    {
        $videoLink = $this->getRawResolvedVideoLink();
        if (!$videoLink) {
            return null;
        }

        $videoLink = $this->normalizeVideoLink($videoLink);
        if (!$videoLink || !$this->isValidVideoLinkUrl($videoLink)) {
            return null;
        }

        return $videoLink;
    }

    protected function getRawResolvedVideoLink(): ?string
    {
        $videoLink = trim((string) ($this->video_link ?? ''));
        return $videoLink !== '' ? $videoLink : null;
    }

    protected function isDirectVideoUrl(string $url): bool
    {
        $path = parse_url($url, PHP_URL_PATH) ?? '';
        return in_array(strtolower(pathinfo($path, PATHINFO_EXTENSION)), ['mp4', 'webm', 'ogg'], true);
    }

    protected function extractYoutubeVideoId(string $url): ?string
    {
        $host = strtolower(parse_url($url, PHP_URL_HOST) ?? '');
        $path = trim((string) parse_url($url, PHP_URL_PATH), '/');
        parse_str((string) parse_url($url, PHP_URL_QUERY), $query);

        if ($host === 'youtu.be') {
            return $this->sanitizeYoutubeId($path);
        }

        if (str_contains($host, 'youtube.com')) {
            if (!empty($query['v'])) {
                return $this->sanitizeYoutubeId($query['v']);
            }
            foreach (['embed/', 'shorts/'] as $needle) {
                if (str_contains($path, $needle)) {
                    return $this->sanitizeYoutubeId(trim(substr($path, strpos($path, $needle) + strlen($needle)), '/'));
                }
            }
        }

        return null;
    }

    protected function extractVimeoVideoId(string $url): ?string
    {
        $host = strtolower(parse_url($url, PHP_URL_HOST) ?? '');
        $path = trim((string) parse_url($url, PHP_URL_PATH), '/');
        if (!str_contains($host, 'vimeo.com') || !$path) {
            return null;
        }
        $segments = array_values(array_filter(explode('/', $path)));
        $candidate = end($segments);
        return ctype_digit((string) $candidate) ? (string) $candidate : null;
    }

    protected function normalizeVideoLink(string $url): ?string
    {
        $url = trim(str_replace(' ', '%20', $url));
        if ($url === '') {
            return null;
        }
        if (str_starts_with($url, '//')) {
            $url = 'https:' . $url;
        }
        if (!preg_match('#^[a-z][a-z0-9+.-]*://#i', $url) && preg_match('/^(www\.)?[\w.-]+\.[a-z]{2,}([\/?#].*)?$/i', $url)) {
            $url = 'https://' . $url;
        }
        return $url;
    }

    protected function isValidVideoLinkUrl(string $url): bool
    {
        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            return false;
        }
        $scheme = strtolower((string) parse_url($url, PHP_URL_SCHEME));
        $host = strtolower((string) parse_url($url, PHP_URL_HOST));
        return in_array($scheme, $this->supportedVideoProtocols, true) && $host !== '' && str_contains($host, '.');
    }

    protected function sanitizeYoutubeId(?string $candidate): ?string
    {
        $candidate = trim((string) $candidate);
        return preg_match('/^[A-Za-z0-9_-]{11}$/', $candidate) ? $candidate : null;
    }
}
