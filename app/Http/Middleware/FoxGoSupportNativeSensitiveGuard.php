<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class FoxGoSupportNativeSensitiveGuard
{
    public function handle(Request $request, Closure $next)
    {
        $admin = auth('admin')->user();

        if (! $admin) {
            return $next($request);
        }

        if ((int) ($admin->role_id ?? 0) === 1) {
            return $next($request);
        }

        if ($this->isRefundRoute($request) && ! $this->hasFoxGoPermission((int) $admin->id, 'can_handle_refund')) {
            abort(403, 'Acesso negado: este funcionário não possui permissão Fox GO para reembolso.');
        }

        if ($this->isRepassesRoute($request) && ! $this->hasFoxGoPermission((int) $admin->id, 'can_handle_repasses')) {
            abort(403, 'Acesso negado: este funcionário não possui permissão Fox GO para repasses/financeiro.');
        }

        return $next($request);
    }

    private function isRefundRoute(Request $request): bool
    {
        return $request->is('admin/refund') || $request->is('admin/refund/*');
    }

    private function isRepassesRoute(Request $request): bool
    {
        if (
            $request->is('admin/transactions/store/withdraw*') ||
            $request->is('admin/transactions/delivery-man/withdraw*') ||
            $request->is('admin/transactions/rider/withdraw*') ||
            $request->is('admin/transactions/store-disbursement*') ||
            $request->is('admin/transactions/dm-disbursement*') ||
            $request->is('admin/transactions/rider-disbursement*') ||
            $request->is('admin/transactions/withdraw-method*') ||
            $request->is('admin/store/withdraw*') ||
            $request->is('admin/business-settings/update-disbursement') ||
            $request->is('admin/business-settings/business-setup/disbursement')
        ) {
            return true;
        }

        if ($request->is('admin/users/delivery-man*') && $request->query('tab') === 'disbursement') {
            return true;
        }

        if ($request->is('admin/store/view/*') && in_array($request->query('tab'), ['disbursement', 'disbursements'], true)) {
            return true;
        }

        if ($request->is('admin/store/view/*') && $request->query('sub_tab') === 'withdraw') {
            return true;
        }

        return false;
    }

    private function hasFoxGoPermission(int $adminId, string $permissionColumn): bool
    {
        $allowedColumns = [
            'can_view_financial_context',
            'can_handle_refund',
            'can_handle_repasses',
        ];

        if (! in_array($permissionColumn, $allowedColumns, true)) {
            return false;
        }

        if (! Schema::hasTable('foxgo_support_admin_departments')) {
            return false;
        }

        return DB::table('foxgo_support_admin_departments')
            ->where('admin_id', $adminId)
            ->where('is_active', 1)
            ->where($permissionColumn, 1)
            ->exists();
    }
}
