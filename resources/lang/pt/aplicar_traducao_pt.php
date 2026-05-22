<?php
/**
 * Fox GO / 6amMart - Aplicar tradução PT-BR em resources/lang/pt/messages.php
 *
 * Uso dentro da VPS:
 *   cd /opt/foxgo/admin/resources/lang/pt
 *   php aplicar_traducao_pt.php
 *
 * Requisitos:
 *   - traduzidos_pt.json na mesma pasta
 *   - messages.php na mesma pasta
 *
 * Segurança:
 *   - Cria backup automático antes de alterar.
 */

$base = __DIR__;
$messagesFile = $base . '/messages.php';
$jsonFile = $base . '/traduzidos_pt.json';

if (!file_exists($messagesFile)) {
    fwrite(STDERR, "ERRO: messages.php não encontrado em $messagesFile\n");
    exit(1);
}

if (!file_exists($jsonFile)) {
    fwrite(STDERR, "ERRO: traduzidos_pt.json não encontrado em $jsonFile\n");
    exit(1);
}

$messages = include $messagesFile;
if (!is_array($messages)) {
    fwrite(STDERR, "ERRO: messages.php não retornou array.\n");
    exit(1);
}

$translations = json_decode(file_get_contents($jsonFile), true);
if (!is_array($translations)) {
    fwrite(STDERR, "ERRO: traduzidos_pt.json inválido.\n");
    exit(1);
}

$backup = $messagesFile . '.bak_' . date('Ymd_His');
if (!copy($messagesFile, $backup)) {
    fwrite(STDERR, "ERRO: não consegui criar backup em $backup\n");
    exit(1);
}

$applied = 0;
$missing = 0;
foreach ($translations as $key => $value) {
    if (array_key_exists($key, $messages)) {
        $messages[$key] = $value;
        $applied++;
    } else {
        $missing++;
    }
}

$content = "<?php\n\nreturn " . var_export($messages, true) . ";\n";
if (file_put_contents($messagesFile, $content) === false) {
    fwrite(STDERR, "ERRO: falha ao escrever messages.php. Backup mantido em $backup\n");
    exit(1);
}

echo "Backup criado: $backup\n";
echo "Traduções aplicadas: $applied\n";
echo "Chaves não encontradas no messages.php: $missing\n";
echo "Arquivo atualizado: $messagesFile\n";
echo "Agora rode no projeto: docker exec foxgo_admin php artisan optimize:clear\n";
