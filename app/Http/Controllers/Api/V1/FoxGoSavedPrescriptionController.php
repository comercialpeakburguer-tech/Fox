<?php

namespace App\Http\Controllers\Api\V1;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\UserFile;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Validator;

class FoxGoSavedPrescriptionController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'errors' => [
                    ['code' => 'unauthorized', 'message' => translate('messages.unauthorized')],
                ],
            ], 401);
        }

        $files = UserFile::where('type', 'prescription')
            ->where('user_id', $user->id)
            ->latest()
            ->get(['id', 'file_name', 'storage'])
            ->map(fn ($file) => [
                'id' => $file->id,
                'file_name' => $file->file_name,
                'image_full_url' => $file->image_full_url,
            ])
            ->values();

        return response()->json([
            'saved_files' => $files,
        ], 200);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'saved_images' => 'required|array|min:1',
            'saved_images.*' => 'required|file|mimes:' . IMAGE_FORMAT_FOR_VALIDATION . '|max:' . MAX_FILE_SIZE * 1024,
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $user = $request->user();

        if (!$user) {
            return response()->json([
                'errors' => [
                    ['code' => 'unauthorized', 'message' => translate('messages.unauthorized')],
                ],
            ], 401);
        }

        $incomingFiles = array_values(array_filter(Arr::wrap($request->file('saved_images'))));
        $existingFiles = UserFile::where('type', 'prescription')
            ->where('user_id', $user->id)
            ->count();

        if (($existingFiles + count($incomingFiles)) > 20) {
            return response()->json([
                'errors' => [
                    ['code' => 'saved_images', 'message' => translate('You can save maximum 20 prescription files')],
                ],
            ], 403);
        }

        $savedFiles = [];

        foreach ($incomingFiles as $file) {
            $fileName = Helpers::upload('order/saved_files/', 'png', $file);

            $savedFile = UserFile::create([
                'user_id' => $user->id,
                'file_name' => $fileName,
                'storage' => Helpers::getDisk(),
                'mime_type' => $file->getMimeType(),
                'type' => 'prescription',
            ]);

            $savedFiles[] = [
                'id' => $savedFile->id,
                'file_name' => $savedFile->file_name,
                'image_full_url' => $savedFile->image_full_url,
            ];
        }

        return response()->json([
            'message' => translate('messages.successfully_added'),
            'files' => $savedFiles,
        ], 200);
    }

    public function deleteAll(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'errors' => [
                    ['code' => 'unauthorized', 'message' => translate('messages.unauthorized')],
                ],
            ], 401);
        }

        $files = UserFile::where('type', 'prescription')
            ->where('user_id', $user->id)
            ->get();

        foreach ($files as $file) {
            Helpers::check_and_delete('order/saved_files/', $file->file_name);
        }

        UserFile::where('type', 'prescription')
            ->where('user_id', $user->id)
            ->delete();

        return response()->json([
            'message' => translate('messages.deleted_successfully'),
        ], 200);
    }
}
