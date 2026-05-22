<?php

namespace App\Console\Commands;

use App\CentralLogics\FoxGoStripeConnectLogic;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Throwable;

class FoxGoRecoverStripeSplits extends Command
{
    protected $signature = 'foxgo:recover-stripe-splits
        {--limit=50 : Quantidade máxima de pedidos para verificar}
        {--days=30 : Janela de dias para procurar pedidos pendentes}
        {--order_id= : Processar apenas um pedido específico}
        {--dry-run : Apenas listar pedidos pendentes, sem criar transfer}';

    protected $description = 'Fox GO: recupera automaticamente pedidos Stripe pagos e entregues que ainda não têm Stripe transfer.';

    public function handle(): int
    {
        $limit = max(1, min((int) $this->option('limit'), 200));
        $days = max(1, min((int) $this->option('days'), 365));
        $orderId = $this->option('order_id');
        $dryRun = (bool) $this->option('dry-run');

        $this->info('===== FOX GO - RECUPERACAO STRIPE SPLITS =====');
        $this->line('Data: ' . now()->toDateTimeString());
        $this->line('dry_run=' . ($dryRun ? 'SIM' : 'NAO'));
        $this->line('limit=' . $limit);
        $this->line('days=' . $days);
        $this->line('order_id=' . ($orderId ?: 'TODOS'));
        $this->newLine();

        foreach (['orders', 'order_transactions', 'stores', 'vendors'] as $table) {
            if (!Schema::hasTable($table)) {
                $this->error("Tabela obrigatoria ausente: {$table}");
                return self::FAILURE;
            }
        }

        foreach (['stripe_transfer_id', 'stripe_payment_intent_id', 'stripe_charge_id'] as $column) {
            if (!Schema::hasColumn('orders', $column)) {
                $this->error("Coluna obrigatoria ausente em orders: {$column}");
                return self::FAILURE;
            }
        }

        $query = DB::table('orders')
            ->where('payment_method', 'stripe')
            ->where('payment_status', 'paid')
            ->where('order_status', 'delivered')
            ->where(function ($q) {
                $q->whereNull('stripe_transfer_id')
                    ->orWhere('stripe_transfer_id', '');
            })
            ->orderBy('id');

        if ($orderId) {
            $query->where('id', (int) $orderId);
        } else {
            $query->where('created_at', '>=', now()->subDays($days));
        }

        $orders = $query->limit($limit)->get([
            'id',
            'store_id',
            'payment_method',
            'payment_status',
            'order_status',
            'order_amount',
            'stripe_payment_intent_id',
            'stripe_charge_id',
            'stripe_transfer_id',
            'created_at',
            'updated_at',
        ]);

        if ($orders->isEmpty()) {
            $this->info('OK: nenhum pedido pendente de split encontrado.');
            info('FoxGoRecoverStripeSplits: nenhum pedido pendente encontrado', [
                'dry_run' => $dryRun,
                'limit' => $limit,
                'days' => $days,
                'order_id' => $orderId,
            ]);

            return self::SUCCESS;
        }

        $this->warn('Pedidos pendentes encontrados: ' . $orders->count());
        $this->newLine();

        $ok = 0;
        $skipped = 0;
        $failed = 0;

        foreach ($orders as $order) {
            $this->line("Pedido {$order->id} | store_id={$order->store_id} | amount={$order->order_amount} | created_at={$order->created_at}");

            if ($dryRun) {
                $skipped++;
                continue;
            }

            try {
                $result = FoxGoStripeConnectLogic::executeForOrder((int) $order->id);

                $this->line('Resultado: ' . json_encode($result, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

                if (($result['ok'] ?? false) === true) {
                    $ok++;
                } else {
                    $skipped++;
                }
            } catch (Throwable $e) {
                $failed++;
                $this->error("Erro no pedido {$order->id}: " . $e->getMessage());

                info('FoxGoRecoverStripeSplits: erro ao recuperar pedido', [
                    'order_id' => $order->id,
                    'error' => $e->getMessage(),
                ]);
            }

            $this->newLine();
        }

        $this->info("Resumo: ok={$ok}, skipped={$skipped}, failed={$failed}, dry_run=" . ($dryRun ? 'SIM' : 'NAO'));

        info('FoxGoRecoverStripeSplits: finalizado', [
            'ok' => $ok,
            'skipped' => $skipped,
            'failed' => $failed,
            'dry_run' => $dryRun,
            'limit' => $limit,
            'days' => $days,
            'order_id' => $orderId,
        ]);

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }
}
