<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Throwable;

class FoxGoPreencherPainelCommand extends Command
{
    protected $signature = 'foxgo:preencher-painel {--apply : Aplica as alterações no banco}';

    protected $description = 'Preenche automaticamente textos institucionais, políticas, landing page e mensagens da Fox GO.';

    public function handle(): int
    {
        $apply = (bool) $this->option('apply');

        $this->info('Fox GO - Preenchimento automático do painel');
        $this->line($apply ? 'MODO: APLICAR ALTERAÇÕES' : 'MODO: RELATÓRIO / DRY-RUN');
        $this->newLine();

        if (!Schema::hasTable('business_settings')) {
            $this->error('Tabela business_settings não encontrada.');
            return self::FAILURE;
        }

        $business = [
            'business_name' => 'Fox GO',
            'footer_text' => 'Fox GO | Delivery local rápido e fácil',
            'cookies_text' => 'Utilizamos cookies para melhorar sua experiência, manter sua sessão segura, analisar o uso da plataforma e oferecer funcionalidades essenciais da Fox GO.',
            'about_us' => $this->aboutUs(),
            'terms_and_conditions' => $this->terms(),
            'privacy_policy' => $this->privacy(),
            'refund_policy' => $this->refund(),
            'cancellation_policy' => $this->cancellation(),
            'cancelation_policy' => $this->cancellation(),
            'shipping_policy' => $this->shipping(),
            'refund_active_status' => '1',
            'refund_policy_status' => '1',
            'cancellation_policy_status' => '1',
            'shipping_policy_status' => '1',
            'order_pending_message' => ['status' => 1, 'message' => 'Seu pedido foi realizado com sucesso'],
            'order_confirmation_msg' => ['status' => 1, 'message' => 'Seu pedido foi confirmado'],
            'order_processing_message' => ['status' => 1, 'message' => 'Seu pedido está sendo preparado'],
            'out_for_delivery_message' => ['status' => 1, 'message' => 'Seu pedido está pronto para entrega'],
            'order_delivered_message' => ['status' => 1, 'message' => 'Seu pedido foi entregue'],
            'delivery_boy_assign_message' => ['status' => 1, 'message' => 'Seu pedido foi atribuído a um entregador'],
            'delivery_boy_start_message' => ['status' => 1, 'message' => 'Seu pedido foi retirado pelo entregador'],
            'delivery_boy_delivered_message' => ['status' => 1, 'message' => 'Pedido entregue com sucesso'],
            'order_handover_message' => ['status' => 1, 'message' => 'O entregador está a caminho'],
            'order_cancled_message' => ['status' => 1, 'message' => 'Pedido cancelado conforme sua solicitação'],
            'order_refunded_message' => ['status' => 1, 'message' => 'Pedido reembolsado com sucesso'],
            'subscription_deadline_warning_message' => 'Sua assinatura está perto do vencimento. Renove para continuar acessando.',
        ];

        foreach ($business as $key => $value) {
            $this->setBusiness($key, $value, $apply);
        }

        $this->mergeBusinessJson('landing_page_text', [
            'header_title_1' => 'Fox GO',
            'header_title_2' => 'Delivery local rápido, fácil e completo',
            'header_title_3' => 'Peça em poucos cliques com a Fox GO',
            'about_title' => 'A Fox GO conecta clientes, lojas, entregadores e parceiros locais.',
            'about_sub_title' => 'Uma plataforma preparada para mercado, comida, farmácia, comércio, encomendas, locações e futuras corridas.',
            'why_choose_us_title' => 'Por que escolher a Fox GO?',
            'why_choose_us_sub_title' => 'Tecnologia, praticidade e operação local em um só ecossistema.',
            'footer_article' => 'Fox GO | Delivery local rápido e fácil',
        ], $apply);

        if (Schema::hasTable('data_settings')) {
            $dataSettings = $this->dataSettings();

            foreach ($dataSettings as $row) {
                $this->setDataSetting($row['type'], $row['key'], $row['value'], $apply);
            }
        } else {
            $this->warn('Tabela data_settings não encontrada. Pulando landing pages avançadas.');
        }

        if ($apply) {
            try {
                $this->callSilent('optimize:clear');
                $this->info('Cache limpo com sucesso.');
            } catch (Throwable $e) {
                $this->warn('Não foi possível limpar cache automaticamente: ' . $e->getMessage());
            }
        }

        $this->newLine();
        $this->info($apply ? 'Preenchimento aplicado.' : 'Dry-run concluído. Nada foi alterado.');
        return self::SUCCESS;
    }

    private function setBusiness(string $key, mixed $value, bool $apply): void
    {
        $value = is_array($value)
            ? json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
            : (string) $value;

        $this->line(($apply ? 'APLICAR' : 'DRY-RUN') . " business_settings.{$key}");

        if (!$apply) {
            return;
        }

        $data = ['value' => $value];

        if (Schema::hasColumn('business_settings', 'updated_at')) {
            $data['updated_at'] = now();
        }

        $insert = $data;
        if (Schema::hasColumn('business_settings', 'created_at')) {
            $insert['created_at'] = now();
        }

        DB::table('business_settings')->updateOrInsert(['key' => $key], $insert);
    }

    private function mergeBusinessJson(string $key, array $merge, bool $apply): void
    {
        $this->line(($apply ? 'APLICAR' : 'DRY-RUN') . " business_settings.{$key} JSON merge");

        if (!$apply) {
            return;
        }

        $current = DB::table('business_settings')->where('key', $key)->value('value');
        $decoded = json_decode((string) $current, true);
        $decoded = is_array($decoded) ? $decoded : [];
        $value = array_merge($decoded, $merge);

        $this->setBusiness($key, $value, true);
    }

    private function setDataSetting(string $type, string $key, string $value, bool $apply): void
    {
        $this->line(($apply ? 'APLICAR' : 'DRY-RUN') . " data_settings.{$type}.{$key}");

        if (!$apply) {
            return;
        }

        $data = ['value' => $value];

        if (Schema::hasColumn('data_settings', 'updated_at')) {
            $data['updated_at'] = now();
        }

        $insert = $data + [
            'type' => $type,
            'key' => $key,
        ];

        if (Schema::hasColumn('data_settings', 'created_at')) {
            $insert['created_at'] = now();
        }

        DB::table('data_settings')->updateOrInsert(
            ['type' => $type, 'key' => $key],
            $insert
        );
    }

    private function dataSettings(): array
    {
        return [
            ['type' => 'admin_landing_page', 'key' => 'fixed_header_title', 'value' => 'Fox GO em uma única plataforma'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_header_sub_title', 'value' => 'Delivery, compras, entregas, serviços e parceiros locais em um ecossistema completo.'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_module_title', 'value' => 'Todos os módulos preparados para sua operação'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_module_sub_title', 'value' => 'Mercado, comida, farmácia, comércio, encomendas, locações e futuras corridas.'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_referal_title', 'value' => 'Indique e acompanhe'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_referal_sub_title', 'value' => 'Expanda a Fox GO com parceiros, clientes e entregadores.'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_newsletter_title', 'value' => 'Receba novidades da Fox GO'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_newsletter_sub_title', 'value' => 'Atualizações, comunicados e informações importantes da plataforma.'],
            ['type' => 'admin_landing_page', 'key' => 'fixed_footer_article_title', 'value' => 'Fox GO é uma plataforma completa para delivery local, parceiros e entregas.'],
            ['type' => 'admin_landing_page', 'key' => 'feature_title', 'value' => 'Funcionalidades para operar com eficiência'],
            ['type' => 'admin_landing_page', 'key' => 'feature_short_description', 'value' => 'Recursos para gestão de pedidos, lojas, entregadores, clientes, pagamentos e módulos de negócio.'],
            ['type' => 'admin_landing_page', 'key' => 'earning_title', 'value' => 'Ganhe com a Fox GO'],
            ['type' => 'admin_landing_page', 'key' => 'earning_sub_title', 'value' => 'Lojistas, entregadores e parceiros podem crescer com a plataforma.'],
            ['type' => 'admin_landing_page', 'key' => 'why_choose_title', 'value' => 'Por que escolher a Fox GO?'],
            ['type' => 'admin_landing_page', 'key' => 'download_user_app_title', 'value' => 'Use a Fox GO de forma simples'],
            ['type' => 'admin_landing_page', 'key' => 'download_user_app_sub_title', 'value' => 'Peça, acompanhe e receba com praticidade.'],
            ['type' => 'admin_landing_page', 'key' => 'testimonial_title', 'value' => 'Quem usa recomenda'],
            ['type' => 'admin_landing_page', 'key' => 'contact_us_title', 'value' => 'Fale com a Fox GO'],
            ['type' => 'admin_landing_page', 'key' => 'contact_us_sub_title', 'value' => 'Tem dúvidas, sugestões ou precisa de suporte? Entre em contato.'],

            ['type' => 'react_landing_page', 'key' => 'header_title', 'value' => '$Fox GO$'],
            ['type' => 'react_landing_page', 'key' => 'header_sub_title', 'value' => 'Delivery local rápido e fácil'],
            ['type' => 'react_landing_page', 'key' => 'header_tag_line', 'value' => 'Uma plataforma para comprar, vender, entregar e crescer.'],
            ['type' => 'react_landing_page', 'key' => 'company_title', 'value' => '$Fox GO$'],
            ['type' => 'react_landing_page', 'key' => 'company_sub_title', 'value' => 'Conectando sua cidade em poucos cliques'],
            ['type' => 'react_landing_page', 'key' => 'company_description', 'value' => 'A Fox GO reúne mercado, restaurantes, farmácias, comércio, encomendas, locações e futuras corridas em uma plataforma moderna para clientes, lojistas, entregadores e parceiros.'],
            ['type' => 'react_landing_page', 'key' => 'company_button_name', 'value' => 'Começar agora'],
            ['type' => 'react_landing_page', 'key' => 'download_user_app_title', 'value' => 'Peça pelo app da Fox GO'],
            ['type' => 'react_landing_page', 'key' => 'download_user_app_sub_title', 'value' => 'Compre, acompanhe pedidos e receba tudo com mais praticidade.'],
            ['type' => 'react_landing_page', 'key' => 'earning_title', 'value' => 'Comece a ganhar com a $Fox GO$'],
            ['type' => 'react_landing_page', 'key' => 'earning_sub_title', 'value' => 'Faça parte de uma rede local de oportunidades.'],
            ['type' => 'react_landing_page', 'key' => 'earning_seller_title', 'value' => 'Seja um lojista parceiro'],
            ['type' => 'react_landing_page', 'key' => 'earning_seller_sub_title', 'value' => 'Venda online, receba pedidos e gerencie sua loja pela Fox GO.'],
            ['type' => 'react_landing_page', 'key' => 'earning_seller_button_name', 'value' => 'Cadastrar loja'],
            ['type' => 'react_landing_page', 'key' => 'earning_dm_title', 'value' => 'Seja um $entregador parceiro$'],
            ['type' => 'react_landing_page', 'key' => 'earning_dm_sub_title', 'value' => 'Receba entregas, acompanhe ganhos e trabalhe com mais autonomia.'],
            ['type' => 'react_landing_page', 'key' => 'earning_dm_button_name', 'value' => 'Cadastrar entregador'],
            ['type' => 'react_landing_page', 'key' => 'business_title', 'value' => '$Gerencie$'],
            ['type' => 'react_landing_page', 'key' => 'business_sub_title', 'value' => 'Sua operação com inteligência'],
            ['type' => 'react_landing_page', 'key' => 'testimonial_title', 'value' => 'Clientes e parceiros que confiam na $Fox GO$'],
            ['type' => 'react_landing_page', 'key' => 'fixed_footer_description', 'value' => 'Acompanhe a Fox GO nos canais oficiais e fique por dentro das novidades.'],
            ['type' => 'react_landing_page', 'key' => 'fixed_newsletter_title', 'value' => 'Fique por dentro'],
            ['type' => 'react_landing_page', 'key' => 'fixed_newsletter_sub_title', 'value' => 'Receba novidades, comunicados e atualizações da Fox GO.'],
            ['type' => 'react_landing_page', 'key' => 'pick_location_title', 'value' => 'Informe sua localização para encontrar opções próximas'],
            ['type' => 'react_landing_page', 'key' => 'trust_sub_title_card_1', 'value' => 'Pedidos entregues'],
            ['type' => 'react_landing_page', 'key' => 'trust_sub_title_card_2', 'value' => 'Clientes atendidos'],
            ['type' => 'react_landing_page', 'key' => 'trust_sub_title_card_3', 'value' => 'Parceiros ativos'],
            ['type' => 'react_landing_page', 'key' => 'trust_sub_title_card_4', 'value' => 'Entregadores cadastrados'],
            ['type' => 'react_landing_page', 'key' => 'available_zone_title', 'value' => 'Áreas e zonas de atendimento'],
            ['type' => 'react_landing_page', 'key' => 'faq_title', 'value' => 'Perguntas frequentes'],
            ['type' => 'react_landing_page', 'key' => 'download_user_app_button_title', 'value' => 'Baixar app do cliente'],
            ['type' => 'react_landing_page', 'key' => 'download_user_app_button_sub_title', 'value' => 'Comprar ficou mais simples.'],
            ['type' => 'react_landing_page', 'key' => 'popular_client_title', 'value' => 'Nossos $parceiros$'],
            ['type' => 'react_landing_page', 'key' => 'popular_client_sub_title', 'value' => 'Lojas, marcas e parceiros locais conectados à Fox GO.'],
            ['type' => 'react_landing_page', 'key' => 'download_seller_app_title', 'value' => 'Venda mais com a $Fox GO$'],
            ['type' => 'react_landing_page', 'key' => 'download_seller_app_sub_title', 'value' => 'Transforme sua loja em uma operação digital e acompanhe seus pedidos.'],
            ['type' => 'react_landing_page', 'key' => 'download_seller_app_button_title', 'value' => 'Começar a vender'],
            ['type' => 'react_landing_page', 'key' => 'download_seller_app_main_button_title', 'value' => 'Baixar app do lojista'],
            ['type' => 'react_landing_page', 'key' => 'download_seller_app_main_button_sub_title', 'value' => 'Controle sua loja de onde estiver.'],
            ['type' => 'react_landing_page', 'key' => 'highlight_title', 'value' => 'Serviços preparados para crescer'],
            ['type' => 'react_landing_page', 'key' => 'highlight_sub_title', 'value' => 'A Fox GO está preparada para delivery, locações e futuros serviços de mobilidade.'],
            ['type' => 'react_landing_page', 'key' => 'download_dm_app_title', 'value' => 'Entregue mais. $Ganhe$ mais.'],
            ['type' => 'react_landing_page', 'key' => 'download_dm_app_sub_title', 'value' => '<p>Cadastre-se como entregador parceiro da Fox GO e transforme entregas em renda.</p><p>• Flexibilidade de horário<br>• Acompanhamento pelo app<br>• Oportunidades locais de entrega</p>'],
            ['type' => 'react_landing_page', 'key' => 'download_dm_app_button_title', 'value' => 'Começar como entregador'],
            ['type' => 'react_landing_page', 'key' => 'download_dm_app_main_button_title', 'value' => 'Baixar app do entregador'],
            ['type' => 'react_landing_page', 'key' => 'download_dm_app_main_button_sub_title', 'value' => 'Gerencie suas entregas com praticidade.'],
            ['type' => 'react_landing_page', 'key' => 'gallery_content_title', 'value' => 'Veja a $Fox GO$ em ação'],
            ['type' => 'react_landing_page', 'key' => 'gallery_content_sub_title', 'value' => 'Conheça como clientes, lojistas e entregadores usam a plataforma.'],
            ['type' => 'react_landing_page', 'key' => 'testimonial_sub_title', 'value' => 'Experiências reais de quem compra, vende e entrega pela Fox GO.'],
            ['type' => 'react_landing_page', 'key' => 'testimonial_button_title', 'value' => 'Começar agora'],

            ['type' => 'flutter_landing_page', 'key' => 'fixed_header_title', 'value' => 'Fox GO'],
            ['type' => 'flutter_landing_page', 'key' => 'fixed_header_sub_title', 'value' => 'Delivery local rápido e fácil'],
            ['type' => 'flutter_landing_page', 'key' => 'fixed_location_title', 'value' => 'Escolha sua localização'],
            ['type' => 'flutter_landing_page', 'key' => 'fixed_module_title', 'value' => 'Todos os serviços em um só lugar'],
            ['type' => 'flutter_landing_page', 'key' => 'fixed_module_sub_title', 'value' => 'Compre, peça, envie e acompanhe pela Fox GO.'],
            ['type' => 'flutter_landing_page', 'key' => 'join_seller_title', 'value' => 'Seja um lojista parceiro'],
            ['type' => 'flutter_landing_page', 'key' => 'join_seller_sub_title', 'value' => 'Cadastre sua loja e venda pela Fox GO.'],
            ['type' => 'flutter_landing_page', 'key' => 'join_seller_button_name', 'value' => 'Cadastrar loja'],
            ['type' => 'flutter_landing_page', 'key' => 'join_delivery_man_title', 'value' => 'Seja entregador parceiro'],
            ['type' => 'flutter_landing_page', 'key' => 'join_delivery_man_sub_title', 'value' => 'Cadastre-se e receba oportunidades de entrega.'],
            ['type' => 'flutter_landing_page', 'key' => 'join_delivery_man_button_name', 'value' => 'Cadastrar entregador'],
            ['type' => 'flutter_landing_page', 'key' => 'download_user_app_title', 'value' => 'Baixe o app e aproveite mais'],
            ['type' => 'flutter_landing_page', 'key' => 'download_user_app_sub_title', 'value' => 'Disponível nos canais oficiais.'],
        ];
    }

    private function aboutUs(): string
    {
        return <<<'HTML'
<h2>Sobre a Fox GO</h2>
<p>A Fox GO é uma plataforma brasileira de tecnologia criada para conectar clientes, lojas parceiras, entregadores, prestadores e futuros motoristas/riders em um ecossistema local simples, rápido e seguro.</p>
<p>Nossa proposta é facilitar o acesso a produtos, serviços, entregas e soluções digitais, permitindo que o cliente encontre opções próximas, que lojistas ampliem suas vendas e que entregadores e parceiros tenham novas oportunidades de atuação.</p>
<p>A Fox GO atua como intermediadora tecnológica entre as partes. As lojas parceiras são responsáveis pelos produtos, preços, disponibilidade, preparo, qualidade e informações cadastradas. Entregadores, prestadores e futuros motoristas/riders são responsáveis pela execução dos serviços aceitos conforme as regras da plataforma.</p>
<p>A plataforma foi preparada para operar com módulos como mercado, alimentação, farmácia, comércio eletrônico, encomendas, logística, locações/rental e futuros serviços de mobilidade, conforme disponibilidade técnica e regulatória.</p>
HTML;
    }

    private function terms(): string
    {
        return <<<'HTML'
<h2>Termos e Condições de Uso da Fox GO</h2>
<p>Estes Termos e Condições regulam o uso da plataforma Fox GO, incluindo site, painéis, aplicativos, módulos, funcionalidades e serviços relacionados.</p>
<h3>1. Papel da Fox GO</h3>
<p>A Fox GO atua como plataforma intermediadora tecnológica entre clientes, lojas parceiras, entregadores, prestadores de serviços, locadores e futuros motoristas/riders. A Fox GO facilita cadastro, exibição, pedido, pagamento, comunicação, acompanhamento e gestão operacional, conforme os recursos disponíveis.</p>
<h3>2. Módulos e serviços abrangidos</h3>
<p>Estes termos abrangem módulos atuais e futuros, incluindo mercado, alimentação, farmácia, comércio eletrônico, encomendas, logística, locações/rental, entregas e futuras corridas ou transporte individual quando disponibilizados.</p>
<h3>3. Responsabilidades dos clientes</h3>
<p>O cliente deve informar dados corretos, endereço completo, telefone válido, acompanhar o pedido ou serviço, conferir informações antes da confirmação e utilizar a plataforma de forma legítima.</p>
<h3>4. Responsabilidades de lojas e parceiros</h3>
<p>Lojas e parceiros são responsáveis por informações, preços, disponibilidade, qualidade, preparo, embalagem, emissão de documentos quando aplicável, cumprimento de normas sanitárias, regulatórias, comerciais e de atendimento ao consumidor.</p>
<h3>5. Responsabilidades de entregadores, prestadores e motoristas/riders</h3>
<p>Entregadores, prestadores e futuros motoristas/riders são responsáveis por executar os serviços aceitos com zelo, segurança, pontualidade, respeito ao usuário, conservação dos itens transportados e observância das leis aplicáveis.</p>
<h3>6. Farmácia, saúde e produtos regulados</h3>
<p>Produtos sujeitos a controle, prescrição, restrição etária, regras sanitárias ou validação documental poderão depender de análise da loja parceira, cumprimento de normas específicas e confirmação no ato da entrega.</p>
<h3>7. Pagamentos</h3>
<p>Pagamentos poderão ocorrer por meios digitais, carteira, dinheiro, métodos offline ou outros recursos habilitados. A confirmação, conciliação, estorno e repasse seguirão as regras do método utilizado, das políticas da Fox GO e das condições de cada parceiro.</p>
<h3>8. Cancelamentos, reembolsos e disputas</h3>
<p>Cancelamentos e reembolsos seguirão as políticas específicas da Fox GO, o status do pedido ou serviço, a natureza do produto ou serviço contratado e a responsabilidade de cada parte envolvida.</p>
<h3>9. Uso proibido</h3>
<p>É proibido usar a plataforma para fraude, abuso, informações falsas, violação de direitos, tentativa de invasão, uso indevido de dados, comercialização irregular ou conduta que prejudique clientes, parceiros, entregadores, prestadores ou a Fox GO.</p>
<h3>10. Alterações</h3>
<p>A Fox GO poderá atualizar estes termos para refletir melhorias, novos módulos, alterações operacionais, exigências legais ou mudanças nos serviços oferecidos.</p>
HTML;
    }

    private function privacy(): string
    {
        return <<<'HTML'
<h2>Política de Privacidade da Fox GO</h2>
<p>A Fox GO respeita a privacidade dos usuários e trata dados pessoais para operar, proteger, melhorar e viabilizar a plataforma.</p>
<h3>1. Dados coletados</h3>
<p>Podemos coletar nome, telefone, e-mail, endereço, localização aproximada ou em tempo real quando necessária, dados de pedidos, dados de pagamento, documentos cadastrais, dados de lojas, entregadores, prestadores, motoristas/riders, dados de dispositivo, logs de acesso e informações de suporte.</p>
<h3>2. Finalidades</h3>
<p>Os dados podem ser usados para cadastro, autenticação, processamento de pedidos, entregas, corridas futuras, locações, suporte, prevenção a fraudes, segurança, comunicação operacional, melhoria da experiência, relatórios internos e cumprimento de obrigações legais.</p>
<h3>3. Compartilhamento operacional</h3>
<p>Para que a plataforma funcione, informações necessárias podem ser compartilhadas entre cliente, loja parceira, entregador, prestador, motorista/rider, meios de pagamento, suporte e fornecedores tecnológicos.</p>
<h3>4. Dados de localização</h3>
<p>Dados de localização podem ser usados para cálculo de distância, zonas de atendimento, entrega, acompanhamento em tempo real, segurança, antifraude e funcionamento de módulos de mobilidade quando disponíveis.</p>
<h3>5. Segurança</h3>
<p>A Fox GO adota medidas técnicas e administrativas para proteger dados contra acessos indevidos, perda, alteração, divulgação não autorizada e uso inadequado.</p>
<h3>6. Direitos do titular</h3>
<p>Usuários podem solicitar orientações, correções, informações ou atendimento relacionado aos seus dados pessoais pelos canais oficiais da Fox GO.</p>
<h3>7. Retenção</h3>
<p>Os dados podem ser mantidos pelo tempo necessário para operação da plataforma, cumprimento legal, prevenção a fraudes, auditoria, suporte e defesa de direitos.</p>
<h3>8. Cookies</h3>
<p>Podemos utilizar cookies e tecnologias semelhantes para login, segurança, preferências, análise de uso e melhoria dos serviços.</p>
HTML;
    }

    private function refund(): string
    {
        return <<<'HTML'
<h2>Política de Reembolso da Fox GO</h2>
<p>Esta política orienta pedidos de reembolso relacionados a compras, entregas, serviços, locações e módulos futuros da Fox GO.</p>
<h3>1. Intermediação</h3>
<p>A Fox GO atua como intermediadora tecnológica. A análise de reembolso pode envolver a loja parceira, entregador, prestador, motorista/rider, método de pagamento e equipe de suporte.</p>
<h3>2. Quando pode haver reembolso</h3>
<p>O reembolso poderá ser analisado em casos como cobrança indevida, cancelamento elegível, item não entregue, produto indisponível após pagamento, divergência relevante, falha operacional comprovada ou situação prevista em lei.</p>
<h3>3. Alimentos, perecíveis e farmácia</h3>
<p>Pedidos com alimentos, perecíveis, itens personalizados, produtos de farmácia ou itens regulados poderão ter regras específicas, considerando preparo, envio, lacre, segurança, conservação, legislação aplicável e responsabilidade do parceiro.</p>
<h3>4. Serviços, locações e corridas futuras</h3>
<p>Serviços, locações e futuras corridas poderão ter reembolso condicionado ao status da execução, deslocamento, aceite do parceiro, tempo de uso, política do prestador e regras exibidas no momento da contratação.</p>
<h3>5. Forma e prazo</h3>
<p>Quando aprovado, o reembolso poderá ocorrer pelo mesmo método de pagamento, carteira, crédito interno ou outro meio informado pela Fox GO, observados prazos de processadores e instituições financeiras.</p>
HTML;
    }

    private function cancellation(): string
    {
        return <<<'HTML'
<h2>Política de Cancelamento da Fox GO</h2>
<p>Cancelamentos dependem do tipo de pedido ou serviço, status da operação, regras do parceiro e condições exibidas na plataforma.</p>
<h3>1. Antes da confirmação</h3>
<p>Pedidos ou solicitações ainda não confirmados podem ser cancelados com maior facilidade, conforme disponibilidade técnica e regras do módulo.</p>
<h3>2. Após confirmação ou preparo</h3>
<p>Após confirmação, preparo, separação, coleta, deslocamento, início de serviço, locação ou corrida futura, o cancelamento pode ser limitado, negado ou gerar cobrança proporcional.</p>
<h3>3. Cancelamento por parceiro</h3>
<p>Lojas, entregadores, prestadores ou motoristas/riders poderão cancelar em situações justificadas, como indisponibilidade, risco, erro operacional, endereço inválido, impossibilidade de contato ou motivo de segurança.</p>
<h3>4. Cancelamento por descumprimento</h3>
<p>A Fox GO poderá cancelar pedidos, contas ou serviços em caso de fraude, abuso, informações falsas, violação de regras ou uso indevido da plataforma.</p>
HTML;
    }

    private function shipping(): string
    {
        return <<<'HTML'
<h2>Política de Envio, Entrega e Serviços da Fox GO</h2>
<p>Esta política se aplica a entregas, encomendas, compras locais, comércio, alimentação, farmácia, mercado, locações e futuros serviços de mobilidade disponibilizados pela Fox GO.</p>
<h3>1. Zonas de atendimento</h3>
<p>A disponibilidade depende de zonas cadastradas, módulos ativos, lojas parceiras, entregadores, prestadores, veículos, horários, distância e condições operacionais.</p>
<h3>2. Prazos estimados</h3>
<p>Tempos de preparo, coleta, entrega, deslocamento ou execução são estimativas e podem variar por clima, trânsito, demanda, endereço, disponibilidade do parceiro ou eventos externos.</p>
<h3>3. Responsabilidade pelo produto</h3>
<p>Lojas e parceiros são responsáveis por qualidade, separação, embalagem, conservação e informações dos produtos. Entregadores são responsáveis pelo transporte adequado após a coleta.</p>
<h3>4. Encomendas e logística</h3>
<p>Encomendas devem respeitar limites de peso, dimensões, conteúdo permitido, segurança e legislação. Itens proibidos, perigosos, ilegais ou não declarados poderão ser recusados.</p>
<h3>5. Locações e mobilidade futura</h3>
<p>Serviços de rental e futuras corridas dependerão de disponibilidade, validação cadastral, regras do parceiro, categoria, veículo, seguro quando aplicável, preço, trajeto e normas locais.</p>
HTML;
    }
}
