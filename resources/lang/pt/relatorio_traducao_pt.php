<?php
/**
 * Fox GO / 6amMart - Relatório EN x PT
 *
 * Uso:
 *   cd /opt/foxgo/admin/resources/lang/pt
 *   php relatorio_traducao_pt.php
 */
$enFile = dirname(__DIR__) . '/en/messages.php';
$ptFile = __DIR__ . '/messages.php';

$en = file_exists($enFile) ? include $enFile : [];
$pt = file_exists($ptFile) ? include $ptFile : [];

$faltando = 0;
$vazios = 0;
$iguais = 0;

foreach ($en as $k => $v) {
    if (!array_key_exists($k, $pt)) {
        $faltando++;
    } elseif (trim((string)$pt[$k]) === '') {
        $vazios++;
    } elseif ((string)$pt[$k] === (string)$v) {
        $iguais++;
    }
}

echo "Total EN: " . count($en) . PHP_EOL;
echo "Total PT: " . count($pt) . PHP_EOL;
echo "Faltando no PT: $faltando" . PHP_EOL;
echo "Vazios no PT: $vazios" . PHP_EOL;
echo "Ainda iguais ao inglês: $iguais" . PHP_EOL;
