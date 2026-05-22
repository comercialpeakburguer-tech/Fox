<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FoxGoSupportCase;
use App\Models\FoxGoSupportDepartment;
use App\Models\FoxGoSupportAdminDepartment;
use App\Models\Admin;
use App\Models\FoxGoSupportCaseTransfer;
use App\Models\FoxGoSupportCaseAction;
use App\Models\FoxGoSupportCaseEvidence;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FoxGoSupportController extends Controller
{

    
    

    public function linkCustomerConversation(Request $request, $caseId)
    {
        $query = FoxGoSupportCase::query();
        $this->foxGoSupportApplyCaseScope($query);

        $supportCase = $query->findOrFail($caseId);
        $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);

        if (empty($supportCase->customer_id)) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Este caso não possui cliente vinculado para criar conversa.');
        }

        $adminId = \Illuminate\Support\Facades\Auth::guard('admin')->id() ?: auth()->id();
        $admin = \App\Models\Admin::find($adminId);

        if (!$admin) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Admin logado não encontrado para criar conversa.');
        }

        $customer = \App\Models\User::find($supportCase->customer_id);

        if (!$customer) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Cliente vinculado ao caso não foi encontrado.');
        }

        $conversation = \Illuminate\Support\Facades\DB::transaction(function () use ($supportCase, $admin, $customer) {
            $adminInfo = \App\Models\UserInfo::query()->where('admin_id', $admin->id)->first();

            if (!$adminInfo) {
                $adminInfo = new \App\Models\UserInfo();
                $adminInfo->admin_id = $admin->id;
                $adminInfo->f_name = $admin->f_name ?? $admin->name ?? 'Admin';
                $adminInfo->l_name = $admin->l_name ?? '';
                $adminInfo->phone = $admin->phone ?? '';
                $adminInfo->email = $admin->email ?? '';
                $adminInfo->image = $admin->image ?? null;
                $adminInfo->save();
            }

            $customerInfo = \App\Models\UserInfo::query()->where('user_id', $customer->id)->first();

            if (!$customerInfo) {
                $customerInfo = new \App\Models\UserInfo();
                $customerInfo->user_id = $customer->id;
                $customerInfo->f_name = $customer->f_name ?? '';
                $customerInfo->l_name = $customer->l_name ?? '';
                $customerInfo->phone = $customer->phone ?? '';
                $customerInfo->email = $customer->email ?? '';
                $customerInfo->image = $customer->image ?? null;
                $customerInfo->save();
            }

            /*
             * Padrão nativo do Admin/ConversationController:
             * conversa admin x cliente usa sender_id=0/sender_type=admin
             * e receiver_id={UserInfo do cliente}/receiver_type=user.
             */
            $conversation = \App\Models\Conversation::query()
                ->where(function ($query) use ($customerInfo) {
                    $query->where('sender_id', 0)
                        ->where('receiver_id', $customerInfo->id);
                })
                ->orWhere(function ($query) use ($customerInfo) {
                    $query->where('sender_id', $customerInfo->id)
                        ->where('receiver_id', 0);
                })
                ->first();

            if (!$conversation) {
                $conversation = new \App\Models\Conversation();
                $conversation->sender_id = 0;
                $conversation->sender_type = 'admin';
                $conversation->receiver_id = $customerInfo->id;
                $conversation->receiver_type = 'user';
                $conversation->unread_message_count = 0;
                $conversation->last_message_time = now();
                $conversation->save();
            }

            $oldConversationId = $supportCase->conversation_id;

            $supportCase->conversation_id = $conversation->id;
            $supportCase->updated_at = now();
            $supportCase->save();

            \App\Models\FoxGoSupportCaseAction::create([
                'case_id' => $supportCase->id,
                'admin_id' => $admin->id,
                'department_id' => $supportCase->current_department_id,
                'action_type' => 'conversation_linked',
                'description' => 'Conversa nativa com o cliente vinculada ao caso. Nenhuma mensagem foi enviada automaticamente.',
                'old_value' => $oldConversationId,
                'new_value' => $conversation->id,
                'metadata' => [
                    'phase' => 'v2c_link_conversa_cliente',
                    'conversation_id' => $conversation->id,
                    'customer_id' => $customer->id,
                    'customer_user_info_id' => $customerInfo->id,
                    'admin_id' => $admin->id,
                    'admin_user_info_id' => $adminInfo->id,
                    'native_chat' => true,
                    'message_sent' => false,
                    'no_order_action' => true,
                    'no_refund_action' => true,
                    'no_payment_gateway_action' => true,
                    'no_repasses_action' => true,
                ],
            ]);

            return $conversation;
        });

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', 'Conversa nativa com o cliente vinculada ao caso. ID da conversa: #' . $conversation->id);
    }


    public function ninaGuidance(Request $request, $caseId)
    {
        $query = FoxGoSupportCase::query();
        $this->foxGoSupportApplyCaseScope($query);

        $supportCase = $query->with([
            'department',
            'assignedAdmin',
            'order',
            'customer',
            'store',
            'deliveryMan',
            'evidences',
            'actions',
            'conversation',
        ])->findOrFail($caseId);

        $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);

        // Fox GO V3C - anti clique/custo Nina
        $lastNinaAction = \Illuminate\Support\Facades\DB::table('foxgo_support_case_actions')
            ->where('case_id', $supportCase->id)
            ->where('action_type', 'nina_guidance')
            ->orderByDesc('id')
            ->first();

        if ($lastNinaAction && \Carbon\Carbon::parse($lastNinaAction->created_at)->greaterThan(now()->subMinutes(2))) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('warning', 'A Nina Atendente já gerou uma orientação há menos de 2 minutos. Aguarde um instante antes de pedir uma nova análise.');
        }

        $order = $supportCase->order;
        $department = $supportCase->department;
        $customer = $supportCase->customer;
        $store = $supportCase->store;
        $deliveryMan = $supportCase->deliveryMan;

        $recentActions = \Illuminate\Support\Facades\DB::table('foxgo_support_case_actions')
            ->where('case_id', $supportCase->id)
            ->orderByDesc('id')
            ->limit(8)
            ->get();

        $conversationMessages = collect();

        if (!empty($supportCase->conversation_id)) {
            $conversationMessages = \Illuminate\Support\Facades\DB::table('messages')
                ->where('conversation_id', $supportCase->conversation_id)
                ->orderByDesc('id')
                ->limit(8)
                ->get()
                ->reverse()
                ->values();
        }

        $context = [
            'case' => [
                'id' => $supportCase->id,
                'protocol' => $supportCase->protocol,
                'status' => $supportCase->status,
                'priority' => $supportCase->priority,
                'department' => $department->name ?? null,
                'reason' => $supportCase->reason,
                'subject' => $supportCase->subject,
                'description' => $supportCase->description,
                'sla_due_at' => $supportCase->sla_due_at,
            ],
            'order' => $order ? [
                'id' => $order->id,
                'status' => $order->order_status ?? null,
                'payment_status' => $order->payment_status ?? null,
                'payment_method' => $order->payment_method ?? null,
                'amount' => $order->order_amount ?? null,
                'delivery_charge' => $order->delivery_charge ?? null,
                'store_id' => $order->store_id ?? null,
                'delivery_man_id' => $order->delivery_man_id ?? null,
            ] : null,
            'participants' => [
                'customer' => $customer ? trim(($customer->f_name ?? '') . ' ' . ($customer->l_name ?? '')) : null,
                'store' => $store->name ?? null,
                'deliveryman' => $deliveryMan ? trim(($deliveryMan->f_name ?? '') . ' ' . ($deliveryMan->l_name ?? '')) : null,
            ],
            'evidences_count' => $supportCase->evidences ? $supportCase->evidences->count() : 0,
            'conversation_id' => $supportCase->conversation_id,
            'conversation_messages_count' => $conversationMessages->count(),
            'recent_actions' => $recentActions->map(function ($action) {
                return [
                    'type' => $action->action_type,
                    'description' => mb_substr((string) $action->description, 0, 500),
                    'created_at' => $action->created_at,
                ];
            })->values()->all(),
            'conversation_messages' => $conversationMessages->map(function ($message) {
                return [
                    'sender_id' => $message->sender_id,
                    'message' => mb_substr((string) $message->message, 0, 500),
                    'created_at' => $message->created_at,
                ];
            })->values()->all(),
        ];

        $provider = 'local';
        $model = null;
        $error = null;
        $guidance = null;

        $systemPrompt = 'Você é Nina Atendente, assistente inteligente da Fox GO e copiloto interno da Central de Suporte. Responda em português brasileiro natural, com tom profissional, direto, humano e operacional. Sua função é ajudar o atendente a resolver o caso mais rápido. Nunca autorize reembolso, Pagar.me ou gateway de pagamento, repasse, cancelamento financeiro, punição, alteração de pedido ou decisão sensível. Você só pode orientar o atendente humano. Sempre peça evidências quando faltarem provas. Toda resposta ao cliente deve ser apenas sugestão para o atendente copiar e enviar manualmente. Não diga que enviou mensagem ao cliente.';

        // Fox GO NINA FINAL - resposta cliente marcada
        $systemPrompt .= ' Na seção 6, gere uma resposta pronta para o cliente, escrita como suporte Fox GO, curta, humana, objetiva e pronta para envio. Coloque a resposta obrigatoriamente entre os marcadores ###RESPOSTA_CLIENTE### e ###FIM_RESPOSTA_CLIENTE###. Dentro desses marcadores deve existir apenas o texto que será enviado ao cliente, sem título, sem markdown e sem explicar que é sugestão. Não prometa reembolso, estorno, repasse, cancelamento aprovado, culpa de loja/entregador/cliente, prazo financeiro, Pagar.me ou gateway de pagamento ou ação sensível. Se faltarem provas, peça foto, print ou explicação objetiva.';
        $userPrompt = "Analise este caso de suporte e gere uma orientação interna para o atendente.\n\n"
            . "Formato obrigatório:\n"
            . "1. Resumo rápido\n"
            . "2. Próxima pergunta ao cliente\n"
            . "3. Evidências necessárias\n"
            . "4. Setor/prioridade sugeridos\n"
            . "5. Riscos ou atenção\n"
            . "6. RESPOSTA PRONTA PARA O CLIENTE
Entre os marcadores ###RESPOSTA_CLIENTE### e ###FIM_RESPOSTA_CLIENTE###, escreva exatamente a mensagem pronta para o cliente.\n\n"
            . "Dados do caso em JSON:\n"
            . json_encode($context, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        try {
            $apiKey = config('openai.api_key');

            if (!empty($apiKey) && class_exists(\OpenAI\Laravel\Facades\OpenAI::class)) {
                $model = config('openai.model') ?: env('OPENAI_MODEL', 'gpt-4o-mini');

                $response = \OpenAI\Laravel\Facades\OpenAI::chat()->create([
                    'model' => $model,
                    'messages' => [
                        ['role' => 'system', 'content' => $systemPrompt],
                        ['role' => 'user', 'content' => $userPrompt],
                    ],
                    'temperature' => 0.2,
                    'max_tokens' => 900,
                ]);

                $guidance = trim($response->choices[0]->message->content ?? '');

                if ($guidance !== '') {
                    $provider = 'openai';
                }
            }
        } catch (\Throwable $e) {
            $error = mb_substr($e->getMessage(), 0, 500);
            $guidance = null;
            $provider = 'local_fallback_after_error';
        }

        if (empty($guidance)) {
            $provider = $provider === 'local_fallback_after_error' ? $provider : 'local_fallback';

            $hasEvidence = ($supportCase->evidences ? $supportCase->evidences->count() : 0) > 0;
            $hasConversation = !empty($supportCase->conversation_id);

            $guidance = "🦊 Nina Atendente\n\n"
                . "1. Resumo rápido\n"
                . "Caso {$supportCase->protocol} vinculado ao pedido #{$supportCase->order_id}. "
                . "Status atual do caso: {$supportCase->status}. Prioridade: {$supportCase->priority}. "
                . "Motivo informado: {$supportCase->reason}. Assunto: {$supportCase->subject}.\n\n"
                . "2. Próxima pergunta ao cliente\n"
                . "Perguntar de forma objetiva o que aconteceu, quando aconteceu e se o problema está relacionado ao produto, entrega, pagamento ou atendimento.\n\n"
                . "3. Evidências necessárias\n"
                . ($hasEvidence
                    ? "Já existe evidência anexada. Conferir se a prova é suficiente antes de escalar para reembolso.\n\n"
                    : "Solicitar print, foto do pedido/produto, comprovante ou descrição detalhada antes de qualquer decisão.\n\n")
                . "4. Setor/prioridade sugeridos\n"
                . "Manter em {$department->name}. Se envolver cobrança, pagamento, reembolso, Pagar.me ou gateway de pagamento ou repasses, transferir para setor financeiro/reembolsos com observação interna.\n\n"
                . "5. Riscos ou atenção\n"
                . "Não executar reembolso, repasse, cancelamento financeiro, punição de loja/entregador ou alteração de pedido sem aprovação humana autorizada.\n\n"
                . "6. Resposta sugerida para o atendente copiar\n"
                . "Olá! Sou do suporte Fox GO. Para analisarmos seu caso com segurança, pode nos enviar uma foto/print que comprove o ocorrido e explicar brevemente o que aconteceu com o pedido? Assim conseguimos encaminhar corretamente sua solicitação.";
        }

        \App\Models\FoxGoSupportCaseAction::create([
            'case_id' => $supportCase->id,
            'admin_id' => \Illuminate\Support\Facades\Auth::guard('admin')->id() ?: auth()->id(),
            'department_id' => $supportCase->current_department_id,
            'action_type' => 'nina_guidance',
            'description' => $guidance,
            'old_value' => null,
            'new_value' => $provider,
            'metadata' => [
                'phase' => 'nina_v3b_copiloto_interno',
                'provider' => $provider,
                'model' => $model,
                'error' => $error,
                'conversation_id' => $supportCase->conversation_id,
                'message_sent' => false,
                'internal_only' => true,
                'v3c_producao' => true,
                'manual_copy_response' => true,
                'anti_double_click_minutes' => 2,
                'no_order_action' => true,
                'no_refund_action' => true,
                'no_payment_gateway_action' => true,
                'no_repasses_action' => true,
                'no_customer_message' => true,
            ],
        ]);

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', 'Nina Atendente gerou uma resposta sugerida para o cliente. Revise antes de enviar pelo chat nativo.');
    }

    public function internalNote(Request $request, $caseId)
    {
        $validated = $request->validate([
            'internal_note' => ['required', 'string', 'max:3000'],
        ], [
            'internal_note.required' => 'Informe o comentário interno do caso.',
        ]);

        $query = FoxGoSupportCase::query();
        $this->foxGoSupportApplyCaseScope($query);

        $supportCase = $query->findOrFail($caseId);
        $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);

        $adminId = \Illuminate\Support\Facades\Auth::guard('admin')->id() ?: auth()->id();

        \Illuminate\Support\Facades\DB::transaction(function () use ($supportCase, $adminId, $validated) {
            FoxGoSupportCaseAction::create([
                'case_id' => $supportCase->id,
                'admin_id' => $adminId,
                'department_id' => $supportCase->current_department_id,
                'action_type' => 'internal_note',
                'description' => 'Comentário interno registrado pela equipe da Central de Suporte Fox GO: ' . $validated['internal_note'],
                'old_value' => null,
                'new_value' => $validated['internal_note'],
                'metadata' => [
                    'phase' => 'fase11_comentario_interno',
                    'internal_note' => $validated['internal_note'],
                    'no_chat' => true,
                    'no_refund' => true,
                    'no_repasses' => true,
                    'no_payment_gateway_action' => true,
                    'no_order_action' => true,
                ],
            ]);

            $supportCase->updated_at = now();
            $supportCase->save();
        });

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', 'Comentário interno registrado no histórico do caso.');
    }

public function statusUpdate(Request $request, $caseId)
    {
        $validated = $request->validate([
            'target_status' => ['required', 'string', 'in:resolved,closed,open'],
            'internal_note' => ['required', 'string', 'max:2000'],
        ], [
            'target_status.required' => 'Informe a ação de status do caso.',
            'target_status.in' => 'Ação de status inválida.',
            'internal_note.required' => 'Informe a observação interna da mudança de status.',
        ]);

        $query = FoxGoSupportCase::query();
        $this->foxGoSupportApplyCaseScope($query);

        $supportCase = $query->findOrFail($caseId);
        $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);

        $statusBefore = $supportCase->status;
        $statusAfter = $validated['target_status'];

        $adminId = \Illuminate\Support\Facades\Auth::guard('admin')->id() ?: auth()->id();

        $updateData = [
            'status' => $statusAfter,
            'updated_at' => now(),
        ];

        if (in_array($statusAfter, ['resolved', 'closed'], true)) {
            $updateData['closed_at'] = now();
            $updateData['closed_by'] = $adminId;
            $updateData['final_decision'] = $validated['internal_note'];
        }

        if ($statusAfter === 'open') {
            $updateData['closed_at'] = null;
            $updateData['closed_by'] = null;
            $updateData['final_decision'] = null;
        }

        \Illuminate\Support\Facades\DB::transaction(function () use ($supportCase, $updateData, $adminId, $statusBefore, $statusAfter, $validated) {
            $supportCase->update($updateData);

            $actionType = 'case_status_updated';
            $description = 'Status do caso atualizado pela equipe interna da Central de Suporte Fox GO.';

            if ($statusAfter === 'resolved') {
                $actionType = 'case_resolved';
                $description = 'Caso marcado como resolvido pela equipe interna da Central de Suporte Fox GO.';
            } elseif ($statusAfter === 'closed') {
                $actionType = 'case_closed';
                $description = 'Caso fechado pela equipe interna da Central de Suporte Fox GO.';
            } elseif ($statusAfter === 'open') {
                $actionType = 'case_reopened';
                $description = 'Caso reaberto pela equipe interna da Central de Suporte Fox GO.';
            }

            FoxGoSupportCaseAction::create([
                'case_id' => $supportCase->id,
                'admin_id' => $adminId,
                'department_id' => $supportCase->current_department_id,
                'action_type' => $actionType,
                'description' => $description . ' Observação interna: ' . $validated['internal_note'],
                'old_value' => $statusBefore,
                'new_value' => $statusAfter,
                'metadata' => [
                    'phase' => 'fase10_status_operacional',
                    'internal_note' => $validated['internal_note'],
                    'closed_at' => $updateData['closed_at'] ?? null,
                    'closed_by' => $updateData['closed_by'] ?? null,
                    'no_refund' => true,
                    'no_repasses' => true,
                    'no_payment_gateway_action' => true,
                ],
            ]);
        });

        $message = 'Status do caso atualizado com histórico registrado.';

        if ($statusAfter === 'resolved') {
            $message = 'Caso marcado como resolvido com histórico registrado.';
        } elseif ($statusAfter === 'closed') {
            $message = 'Caso fechado com histórico registrado.';
        } elseif ($statusAfter === 'open') {
            $message = 'Caso reaberto com histórico registrado.';
        }

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', $message);
    }

public function evidence(Request $request, $caseId)
    {
        $validated = $request->validate([
            'evidence_type' => ['nullable', 'string', 'max:100'],
            'note' => ['nullable', 'string', 'max:2000'],
            'evidence_file' => ['nullable', 'file', 'max:10240', 'mimes:jpg,jpeg,png,webp,pdf,txt'],
        ]);

        $supportCase = FoxGoSupportCase::query()->findOrFail($caseId);

        // FOXGO_GUARD_EVIDENCE_CURRENT_DEPARTMENT
        $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);

        $filePath = null;
        $metadata = [];

        if ($request->hasFile('evidence_file')) {
            $file = $request->file('evidence_file');
            $directory = 'foxgo_support/evidences/' . now()->format('Y/m');
            $filename = 'case_' . $supportCase->id . '_' . now()->format('Ymd_His') . '_' . Str::random(8) . '.' . $file->getClientOriginalExtension();

            $filePath = $file->storeAs($directory, $filename, 'public');

            $metadata = [
                'original_name' => $file->getClientOriginalName(),
                'mime_type' => $file->getClientMimeType(),
                'size' => $file->getSize(),
            ];
        }

        if (!$filePath && empty($validated['note'])) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Informe uma observação ou anexe um arquivo.');
        }

        DB::transaction(function () use ($supportCase, $validated, $filePath, $metadata) {
            $evidence = FoxGoSupportCaseEvidence::create([
                'case_id' => $supportCase->id,
                'uploaded_by_type' => 'admin',
                'uploaded_by_id' => auth('admin')->id(),
                'evidence_type' => $validated['evidence_type'] ?? 'geral',
                'file' => $filePath,
                'note' => $validated['note'] ?? null,
                'metadata' => $metadata ?: null,
            ]);

            FoxGoSupportCaseAction::create([
                'case_id' => $supportCase->id,
                'admin_id' => auth('admin')->id(),
                'department_id' => $supportCase->current_department_id,
                'action_type' => 'evidence_added',
                'description' => 'Evidência adicionada ao caso da Central de Suporte Fox GO.',
                'metadata' => [
                    'evidence_id' => $evidence->id,
                    'evidence_type' => $evidence->evidence_type,
                    'has_file' => (bool) $evidence->file,
                ],
            ]);
        });

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', 'Evidência adicionada ao caso.');
    }

    public function transfer(Request $request, $caseId)
    {
        $validated = $request->validate([
            'to_department_id' => ['required', 'integer', 'exists:foxgo_support_departments,id'],
            'reason' => ['nullable', 'string', 'max:255'],
            'internal_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $supportCase = FoxGoSupportCase::query()->findOrFail($caseId);

        // FOXGO_GUARD_TRANSFER_CURRENT_DEPARTMENT
        $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);

        $fromDepartmentId = $supportCase->current_department_id;
        $toDepartmentId = (int) $validated['to_department_id'];

        if ($fromDepartmentId === $toDepartmentId) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'O caso já está neste setor.');
        }

        DB::transaction(function () use ($supportCase, $fromDepartmentId, $toDepartmentId, $validated) {
            $statusBefore = $supportCase->status;
            $statusAfter = 'encaminhado';

            FoxGoSupportCaseTransfer::create([
                'case_id' => $supportCase->id,
                'from_department_id' => $fromDepartmentId,
                'to_department_id' => $toDepartmentId,
                'from_admin_id' => auth('admin')->id(),
                'to_admin_id' => null,
                'reason' => $validated['reason'] ?? null,
                'internal_note' => $validated['internal_note'] ?? null,
                'status_before' => $statusBefore,
                'status_after' => $statusAfter,
            ]);

            $supportCase->update([
                'current_department_id' => $toDepartmentId,
                'assigned_admin_id' => null,
                'status' => $statusAfter,
            ]);

            FoxGoSupportCaseAction::create([
                'case_id' => $supportCase->id,
                'admin_id' => auth('admin')->id(),
                'department_id' => $toDepartmentId,
                'action_type' => 'department_transfer',
                'description' => 'Caso transferido entre setores da Central de Suporte Fox GO.',
                'old_value' => (string) $fromDepartmentId,
                'new_value' => (string) $toDepartmentId,
                'metadata' => [
                    'reason' => $validated['reason'] ?? null,
                    'internal_note' => $validated['internal_note'] ?? null,
                    'status_before' => $statusBefore,
                    'status_after' => $statusAfter,
                ],
            ]);
        });

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', 'Caso transferido com histórico registrado.');
    }



    public function create(\Illuminate\Http\Request $request)
    {
        $visibleDepartmentIds = $this->foxGoSupportVisibleDepartmentIds();

        if (!$this->foxGoSupportIsMaster() && empty($visibleDepartmentIds)) {
            abort(403, 'Acesso negado: funcionário sem setor ativo na Central de Suporte.');
        }

        $departments = FoxGoSupportDepartment::query()
            ->where('is_active', true)
            ->when(!$this->foxGoSupportIsMaster(), function ($query) use ($visibleDepartmentIds) {
                $query->whereIn('id', $visibleDepartmentIds);
            })
            ->orderBy('id')
            ->get();

        $statuses = [
            'open' => 'Aberto',
            'aberto' => 'Aberto',
            'em_atendimento' => 'Em atendimento',
            'aguardando_cliente' => 'Aguardando cliente',
            'aguardando_loja' => 'Aguardando loja',
            'aguardando_entregador' => 'Aguardando entregador',
            'encaminhado' => 'Encaminhado',
            'em_analise_reembolso' => 'Em análise de reembolso',
            'em_analise_financeira' => 'Em análise financeira',
            'em_emergencia' => 'Em emergência',
            'resolved' => 'Resolvido',
            'resolvido' => 'Resolvido',
            'closed' => 'Fechado',
            'fechado' => 'Fechado',
        ];

        $priorities = [
            'low' => 'Baixa',
            'baixa' => 'Baixa',
            'normal' => 'Normal',
            'medium' => 'Média',
            'media' => 'Média',
            'high' => 'Alta',
            'alta' => 'Alta',
            'urgent' => 'Urgente',
            'urgente' => 'Urgente',
            'emergencia' => 'Emergência',
        ];

        $recentOrders = DB::table('orders')
            ->leftJoin('users', 'users.id', '=', 'orders.user_id')
            ->leftJoin('stores', 'stores.id', '=', 'orders.store_id')
            ->leftJoin('delivery_men', 'delivery_men.id', '=', 'orders.delivery_man_id')
            ->where('orders.created_at', '>=', now()->subDay()->startOfDay())
            ->select(
                'orders.id',
                'orders.order_amount',
                'orders.payment_method',
                'orders.payment_status',
                'orders.order_status',
                'orders.created_at',
                'users.f_name as customer_f_name',
                'users.l_name as customer_l_name',
                'stores.name as store_name',
                'delivery_men.f_name as dm_f_name',
                'delivery_men.l_name as dm_l_name'
            )
            ->orderByDesc('orders.id')
            ->limit(100)
            ->get();

        
        // Fox GO Fase 9 - pedidos recentes/busca para criacao de chamado
        $orderSearch = trim((string) $request->query('order_search', ''));
        $recentOrdersQuery = \Illuminate\Support\Facades\DB::table('orders')
            ->leftJoin('stores', 'stores.id', '=', 'orders.store_id')
            ->select([
                'orders.id',
                'orders.created_at',
                'orders.store_id',
                'orders.delivery_man_id',
                'orders.order_status',
                'orders.payment_status',
                'orders.payment_method',
                'orders.order_amount',
                'orders.delivery_charge',
                'stores.name as store_name',
            ]);

        if ($orderSearch !== '') {
            $cleanOrderSearch = preg_replace('/\D+/', '', $orderSearch);

            if ($cleanOrderSearch !== '') {
                $recentOrdersQuery->where('orders.id', (int) $cleanOrderSearch);
            } else {
                $recentOrdersQuery->whereRaw('1 = 0');
            }
        } else {
            $recentOrdersQuery->whereBetween('orders.created_at', [
                \Illuminate\Support\Carbon::yesterday()->startOfDay(),
                \Illuminate\Support\Carbon::now()->endOfDay(),
            ]);
        }

        $recentOrders = $recentOrdersQuery
            ->orderByDesc('orders.id')
            ->limit(50)
            ->get();

        \Illuminate\Support\Facades\View::share('recentOrders', $recentOrders);
        \Illuminate\Support\Facades\View::share('orderSearch', $orderSearch);
return view('admin-views.foxgo-support.create', compact('departments', 'statuses', 'priorities', 'recentOrders'));
    }



    public function store(Request $request)
    {
        // Fox GO Fase 9 - valida campos operacionais obrigatorios
        $request->validate([
            'order_id' => ['required', 'integer', 'exists:orders,id'],
            'reason' => ['required', 'string', 'max:255'],
            'subject' => ['required', 'string', 'max:255'],
        ], [
            'order_id.required' => 'Selecione o pedido vinculado ao caso.',
            'order_id.exists' => 'Pedido vinculado não encontrado.',
            'reason.required' => 'Informe o motivo do caso.',
            'subject.required' => 'Informe o assunto do caso.',
        ]);

        $validated = $request->validate([
            'department_id' => ['required', 'integer', 'exists:foxgo_support_departments,id'],
            'order_id' => ['nullable', 'integer'],
            'order_search_id' => ['nullable', 'integer'],
            'status' => ['required', 'string', 'max:100'],
            'priority' => ['required', 'string', 'max:100'],
            'reason' => ['required', 'string', 'max:150'],
            'subject' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:3000'],
        ]);

        $selectedOrderId = $validated['order_search_id'] ?? $validated['order_id'] ?? null;

        // FOXGO_GUARD_STORE_DEPARTMENT
        $this->foxGoSupportEnsureAccessToDepartment((int) $validated['department_id']);

        if (!$selectedOrderId) {
            return redirect()
                ->route('admin.support.cases.create')
                ->withInput()
                ->with('error', 'Selecione um pedido recente ou informe o número do pedido.');
        }

        $order = null;
        $customerId = null;
        $storeId = null;
        $vendorId = null;
        $deliveryManId = null;

        $order = DB::table('orders')->where('id', (int) $selectedOrderId)->first();

        if (!$order) {
            return redirect()
                ->route('admin.support.cases.create')
                ->withInput()
                ->with('error', 'Pedido não encontrado para vincular ao caso.');
        }

        $customerId = $order->user_id ?? null;
        $storeId = $order->store_id ?? null;
        $deliveryManId = $order->delivery_man_id ?? null;

        if ($storeId) {
            $vendorId = DB::table('stores')->where('id', $storeId)->value('vendor_id');
        }

        $protocol = null;

        do {
            $protocol = 'FGSUP-' . now()->format('Ymd-His') . '-' . random_int(100, 999);
        } while (FoxGoSupportCase::where('protocol', $protocol)->exists());

        $supportCase = DB::transaction(function () use ($validated, $protocol, $selectedOrderId, $customerId, $storeId, $vendorId, $deliveryManId, $order) {
            $case = FoxGoSupportCase::create([
                'protocol' => $protocol,
                'order_id' => $selectedOrderId,
                'customer_id' => $customerId,
                'store_id' => $storeId,
                'vendor_id' => $vendorId,
                'delivery_man_id' => $deliveryManId,
                'opened_by_type' => 'admin_internal',
                'opened_by_id' => auth('admin')->id(),
                'current_department_id' => (int) $validated['department_id'],
                'assigned_admin_id' => auth('admin')->id(),
                'status' => $validated['status'],
                'priority' => $validated['priority'],
                'reason' => $validated['reason'] ?? null,
                'subject' => $validated['subject'],
                'description' => $validated['description'] ?? null,
                'sla_due_at' => now()->addHours(24),
            ]);

            FoxGoSupportCaseAction::create([
                'case_id' => $case->id,
                'admin_id' => auth('admin')->id(),
                'department_id' => (int) $validated['department_id'],
                'action_type' => 'case_created_internal',
                'description' => 'Caso criado manualmente pela equipe interna da Central de Suporte Fox GO.',
                'metadata' => [
                    'has_order' => (bool) $order,
                    'order_id' => $selectedOrderId,
                    'customer_id' => $customerId,
                    'store_id' => $storeId,
                    'vendor_id' => $vendorId,
                    'delivery_man_id' => $deliveryManId,
                    'no_chat' => true,
                    'no_refund' => true,
                    'no_repasses' => true,
                ],
            ]);

            return $case;
        });

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', 'Caso criado com sucesso.');
    }

    public function cases(Request $request)
    {
        $visibleDepartmentIds = $this->foxGoSupportVisibleDepartmentIds();

        if (!$this->foxGoSupportIsMaster() && empty($visibleDepartmentIds)) {
            abort(403, 'Acesso negado: funcionário sem setor ativo na Central de Suporte.');
        }

        $departments = FoxGoSupportDepartment::query()
            ->where('is_active', true)
            ->when(!$this->foxGoSupportIsMaster(), function ($query) use ($visibleDepartmentIds) {
                $query->whereIn('id', $visibleDepartmentIds);
            })
            ->orderBy('id')
            ->get();

        $statuses = [
            'open' => 'Aberto',
            'aberto' => 'Aberto',
            'em_atendimento' => 'Em atendimento',
            'aguardando_cliente' => 'Aguardando cliente',
            'aguardando_loja' => 'Aguardando loja',
            'aguardando_entregador' => 'Aguardando entregador',
            'encaminhado' => 'Encaminhado',
            'em_analise_reembolso' => 'Em análise de reembolso',
            'em_analise_financeira' => 'Em análise financeira',
            'em_emergencia' => 'Em emergência',
            'resolved' => 'Resolvido',
            'resolvido' => 'Resolvido',
            'closed' => 'Fechado',
            'fechado' => 'Fechado',
        ];

        $priorities = [
            'low' => 'Baixa',
            'baixa' => 'Baixa',
            'normal' => 'Normal',
            'medium' => 'Média',
            'media' => 'Média',
            'high' => 'Alta',
            'alta' => 'Alta',
            'urgent' => 'Urgente',
            'urgente' => 'Urgente',
            'emergencia' => 'Emergência',
        ];

        $query = FoxGoSupportCase::query()
            ->with(['department', 'order', 'customer', 'store', 'deliveryMan', 'assignedAdmin']);

        $this->foxGoSupportApplyCaseScope($query);

        if ($request->filled('department_id')) {
            $this->foxGoSupportEnsureAccessToDepartment((int) $request->department_id);
            $query->where('current_department_id', (int) $request->department_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('priority')) {
            $query->where('priority', $request->priority);
        }

        if ($request->filled('search')) {
            $search = trim((string) $request->search);
            $query->where(function ($q) use ($search) {
                $q->where('protocol', 'like', "%{$search}%")
                    ->orWhere('subject', 'like', "%{$search}%")
                    ->orWhere('reason', 'like', "%{$search}%")
                    ->orWhere('order_id', $search);
            });
        }

        $cases = $query->orderByDesc('id')->paginate(20)->withQueryString();

        $stats = [
            'total_cases' => $totalCases,
            'open_cases' => $openCases,
            'refund_cases' => $refundCases,
            'emergency_cases' => $securityCases,
        ];

        $isSupportMaster = $this->foxGoSupportIsMaster();

        return view('admin-views.foxgo-support.cases', compact('cases', 'departments', 'statuses', 'priorities', 'isSupportMaster', 'visibleDepartmentIds'));
    }




    public function show($caseId)
    {
        $supportCase = FoxGoSupportCase::with([
            'department',
            'order',
            'customer',
            'store',
            'vendor',
            'deliveryMan',
            'conversation',
            'assignedAdmin',
            'transfers.fromDepartment',
            'transfers.toDepartment',
            'evidences',
            'actions',
        ])->findOrFail($caseId);

        $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);

        $departments = FoxGoSupportDepartment::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->get();

        $supportPermissions = $this->foxGoSupportPermissionsForDepartment($supportCase->current_department_id);

        $orderTransaction = null;

        if ($supportCase->order_id && ($supportPermissions['can_view_financial_context'] ?? false)) {
            $orderTransaction = DB::table('order_transactions')
                ->where('order_id', $supportCase->order_id)
                ->orderByDesc('id')
                ->first();
        }
$isSupportMaster = $this->foxGoSupportIsMaster();

        return view('admin-views.foxgo-support.show', compact(
            'supportCase',
            'departments',
            'orderTransaction',
            'supportPermissions',
            'isSupportMaster'
        ));
    }






    private function foxGoSupportIsMaster(): bool
    {
        return (int) optional(auth('admin')->user())->role_id === 1;
    }

    private function foxGoSupportVisibleDepartmentIds(): array
    {
        if ($this->foxGoSupportIsMaster()) {
            return FoxGoSupportDepartment::query()
                ->where('is_active', true)
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->all();
        }

        return FoxGoSupportAdminDepartment::query()
            ->where('admin_id', auth('admin')->id())
            ->where('is_active', true)
            ->pluck('department_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    private function foxGoSupportApplyCaseScope($query): void
    {
        if ($this->foxGoSupportIsMaster()) {
            return;
        }

        $departmentIds = $this->foxGoSupportVisibleDepartmentIds();

        if (empty($departmentIds)) {
            $query->whereRaw('1 = 0');
            return;
        }

        $query->whereIn('current_department_id', $departmentIds);
    }

    private function foxGoSupportEnsureAccessToDepartment($departmentId): void
    {
        if ($this->foxGoSupportIsMaster()) {
            return;
        }

        $departmentId = (int) $departmentId;
        $departmentIds = $this->foxGoSupportVisibleDepartmentIds();

        if (!$departmentId || empty($departmentIds) || !in_array($departmentId, $departmentIds, true)) {
            abort(403, 'Acesso negado: este caso pertence a outro setor da Central de Suporte.');
        }
    }

    private function foxGoSupportPermissionsForDepartment($departmentId = null): array
    {
        if ($this->foxGoSupportIsMaster()) {
            return [
                'can_view_financial_context' => true,
                'can_handle_refund' => true,
                'can_handle_repasses' => true,
            ];
        }

        $query = FoxGoSupportAdminDepartment::query()
            ->where('admin_id', auth('admin')->id())
            ->where('is_active', true);

        if ($departmentId) {
            $query->where('department_id', (int) $departmentId);
        }

        $assignment = $query->first();

        return [
            'can_view_financial_context' => (bool) optional($assignment)->can_view_financial_context,
            'can_handle_refund' => (bool) optional($assignment)->can_handle_refund,
            'can_handle_repasses' => (bool) optional($assignment)->can_handle_repasses,
        ];
    }

    public function team()
    {
        if ((int) auth('admin')->user()->role_id !== 1) {
            abort(403, 'Apenas Master admin pode gerenciar equipe da Central de Suporte.');
        }

        $admins = Admin::query()
            ->with('role')
            ->orderByRaw("CASE WHEN role_id = 1 THEN 0 ELSE 1 END")
            ->orderBy('f_name')
            ->get();

        $departments = FoxGoSupportDepartment::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->get();

        $assignments = FoxGoSupportAdminDepartment::query()
            ->with(['admin', 'department'])
            ->orderByDesc('is_active')
            ->orderBy('department_id')
            ->orderBy('admin_id')
            ->get();

        return view('admin-views.foxgo-support.team', compact('admins', 'departments', 'assignments'));
    }

    public function teamAssign(Request $request)
    {
        if ((int) auth('admin')->user()->role_id !== 1) {
            abort(403, 'Apenas Master admin pode gerenciar equipe da Central de Suporte.');
        }

        $validated = $request->validate([
            'admin_id' => ['required', 'integer', 'exists:admins,id'],
            'department_id' => ['required', 'integer', 'exists:foxgo_support_departments,id'],
            'role_in_department' => ['nullable', 'string', 'max:100'],
            'can_view_financial_context' => ['nullable'],
            'can_handle_refund' => ['nullable'],
            'can_handle_repasses' => ['nullable'],
        ]);

        FoxGoSupportAdminDepartment::updateOrCreate(
            [
                'admin_id' => (int) $validated['admin_id'],
                'department_id' => (int) $validated['department_id'],
            ],
            [
                'role_in_department' => $validated['role_in_department'] ?? 'atendente',
                'can_view_financial_context' => $request->has('can_view_financial_context'),
                'can_handle_refund' => $request->has('can_handle_refund'),
                'can_handle_repasses' => $request->has('can_handle_repasses'),
                'is_active' => true,
            ]
        );

        return redirect()
            ->route('admin.support.team')
            ->with('success', 'Funcionário vinculado ao setor da Central de Suporte.');
    }

    public function teamToggle($id)
    {
        if ((int) auth('admin')->user()->role_id !== 1) {
            abort(403, 'Apenas Master admin pode gerenciar equipe da Central de Suporte.');
        }

        $assignment = FoxGoSupportAdminDepartment::query()->findOrFail($id);
        $assignment->update([
            'is_active' => ! $assignment->is_active,
        ]);

        return redirect()
            ->route('admin.support.team')
            ->with('success', 'Status do vínculo atualizado.');
    }

    public function index()
    {
        $visibleDepartmentIds = $this->foxGoSupportVisibleDepartmentIds();

        if (!$this->foxGoSupportIsMaster() && empty($visibleDepartmentIds)) {
            abort(403, 'Acesso negado: funcionário sem setor ativo na Central de Suporte.');
        }

        $departments = FoxGoSupportDepartment::query()
            ->where('is_active', true)
            ->when(!$this->foxGoSupportIsMaster(), function ($query) use ($visibleDepartmentIds) {
                $query->whereIn('id', $visibleDepartmentIds);
            })
            ->orderBy('id')
            ->get();

        $caseBase = FoxGoSupportCase::query();
        $this->foxGoSupportApplyCaseScope($caseBase);

        $totalCases = (clone $caseBase)->count();
        $openCases = (clone $caseBase)->whereIn('status', [
            'open',
            'aberto',
            'em_atendimento',
            'encaminhado',
            'em_analise_reembolso',
            'em_analise_financeira',
            'aguardando_cliente',
            'aguardando_loja',
            'aguardando_entregador',
        ])->count();

        $refundCases = (clone $caseBase)
            ->whereHas('department', fn ($q) => $q->where('slug', 'central_reembolsos'))
            ->count();

        $securityCases = (clone $caseBase)
            ->whereHas('department', fn ($q) => $q->where('slug', 'seguranca_emergencia'))
            ->count();

        foreach ($departments as $department) {
            $deptQuery = FoxGoSupportCase::query()->where('current_department_id', $department->id);
            $this->foxGoSupportApplyCaseScope($deptQuery);

            $total = (clone $deptQuery)->count();
            $open = (clone $deptQuery)->whereIn('status', [
                'aberto',
                'em_atendimento',
                'encaminhado',
                'em_analise_reembolso',
                'em_analise_financeira',
                'aguardando_cliente',
                'aguardando_loja',
                'aguardando_entregador',
            ])->count();
            $urgent = (clone $deptQuery)->whereIn('priority', ['urgent', 'high', 'urgente', 'emergencia'])->count();

            $department->total_cases = $total;
            $department->cases_count = $total;
            $department->open_cases = $open;
            $department->open_cases_count = $open;
            $department->urgent_cases = $urgent;
            $department->urgent_cases_count = $urgent;
        }

        $stats = [
            'total_cases' => $totalCases,
            'open_cases' => $openCases,
            'refund_cases' => $refundCases,
            'emergency_cases' => $securityCases,
        ];

        $isSupportMaster = $this->foxGoSupportIsMaster();

        return view('admin-views.foxgo-support.index', compact(
            'departments',
            'stats',
            'totalCases',
            'openCases',
            'refundCases',
            'securityCases',
            'visibleDepartmentIds',
            'isSupportMaster'
        ));
    }


        public function sendNinaCustomerMessage($caseId, \Illuminate\Http\Request $request)
    {
        $supportCase = \App\Models\FoxGoSupportCase::findOrFail($caseId);

        if (method_exists($this, 'foxGoSupportEnsureAccessToDepartment')) {
            $this->foxGoSupportEnsureAccessToDepartment($supportCase->current_department_id);
        }

        $messageText = trim((string) $request->input('nina_customer_message', ''));

        if ($messageText === '' || mb_strlen($messageText) < 10) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Informe uma mensagem válida antes de enviar ao cliente.');
        }

        if (mb_strlen($messageText) > 1500) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'A mensagem está muito grande. Use no máximo 1500 caracteres.');
        }

        if ((string) $request->input('nina_customer_approved') !== '1') {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Confirme que revisou a resposta da Nina antes de enviar ao cliente.');
        }

        $dangerPatterns = [
            '/reembolso\s+(aprovado|confirmado|feito|liberado)/iu',
            '/estorno\s+(aprovado|confirmado|feito|liberado)/iu',
            '/repasse\s+(feito|confirmado|liberado|enviado)/iu',
            '/transfer[eê]ncia\s+(feita|confirmada|liberada|enviada)/iu',
            '/pedido\s+(cancelado|alterado)\s+(com\s+sucesso|confirmado|aprovado)/iu',
            '/cancelamento\s+(aprovado|confirmado|feito)/iu',
            '/valor\s+(devolvido|estornado|reembolsado)/iu',
            '/dinheiro\s+(devolvido|estornado|reembolsado)/iu',
            '/pix\s+(enviado|feito|confirmado)/iu',
            '/pagar\.?me\s+(confirmado|feito|executado|transferido|reembolsado|estornado|liberado)/iu',
            '/gateway\s+de\s+pagamento\s+(confirmado|feito|executado|transferido|reembolsado|estornado|liberado)/iu',
            '/cobran[çc]a\s+(confirmada|feita|executada|reembolsada|estornada|liberada)/iu',
            '/split\s+(feito|confirmado|executado)/iu',
            '/culpa\s+da\s+(loja|Fox GO|fox go|entregador|cliente)/iu',
        ];

        foreach ($dangerPatterns as $pattern) {
            if (preg_match($pattern, $messageText)) {
                return redirect()
                    ->route('admin.support.cases.show', $supportCase->id)
                    ->with('error', 'Mensagem bloqueada por segurança. A Nina não pode prometer reembolso, estorno, repasse, cancelamento, Pagar.me, gateway de pagamento, culpa ou decisão financeira.');
            }
        }

        $admin = \App\Models\Admin::find(auth('admin')->id());

        if (!$admin) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Admin autenticado não encontrado.');
        }

        $customer = \App\Models\User::find($supportCase->customer_id);

        if (!$customer) {
            return redirect()
                ->route('admin.support.cases.show', $supportCase->id)
                ->with('error', 'Cliente do caso não encontrado.');
        }

        $messageId = null;
        $conversationId = null;

        \Illuminate\Support\Facades\DB::transaction(function () use ($supportCase, $admin, $customer, $messageText, &$messageId, &$conversationId) {
            // Mesmo padrão do ConversationController nativo: sender da mensagem é o UserInfo do admin.
            $sender = \App\Models\UserInfo::where('admin_id', $admin->id)->first();

            if (!$sender) {
                $sender = new \App\Models\UserInfo();
                $sender->admin_id = $admin->id;
                $sender->f_name = $admin->f_name;
                $sender->l_name = $admin->l_name;
                $sender->phone = $admin->phone;
                $sender->email = $admin->email;
                $sender->image = $admin->image;
                $sender->save();
            }

            $receiver = \App\Models\UserInfo::where('user_id', $customer->id)->first();

            if (!$receiver) {
                $receiver = new \App\Models\UserInfo();
                $receiver->user_id = $customer->id;
                $receiver->f_name = $customer->f_name;
                $receiver->l_name = $customer->l_name;
                $receiver->phone = $customer->phone;
                $receiver->email = $customer->email;
                $receiver->image = $customer->image;
                $receiver->save();
            }

            $conversation = null;

            if (!empty($supportCase->conversation_id)) {
                $conversation = \App\Models\Conversation::find($supportCase->conversation_id);
            }

            if (!$conversation) {
                $conversation = \App\Models\Conversation::whereConversation($receiver->id, 0)->first();
            }

            if (!$conversation) {
                $conversation = new \App\Models\Conversation();
                $conversation->sender_id = 0;
                $conversation->sender_type = 'admin';
                $conversation->receiver_id = $receiver->id;
                $conversation->receiver_type = 'user';
                $conversation->last_message_time = now()->toDateTimeString();
                $conversation->save();
            }

            if ((int) $supportCase->conversation_id !== (int) $conversation->id) {
                \Illuminate\Support\Facades\DB::table('foxgo_support_cases')
                    ->where('id', $supportCase->id)
                    ->update([
                        'conversation_id' => $conversation->id,
                        'updated_at' => now(),
                    ]);
            }

            $message = new \App\Models\Message();
            $message->conversation_id = $conversation->id;
            $message->sender_id = $sender->id;
            $message->message = $messageText;

            if (\Illuminate\Support\Facades\Schema::hasColumn('messages', 'order_id')) {
                $message->order_id = $supportCase->order_id;
            }

            if (\Illuminate\Support\Facades\Schema::hasColumn('messages', 'is_seen')) {
                $message->is_seen = 0;
            }

            $message->save();

            $conversation->unread_message_count = $conversation->unread_message_count ? $conversation->unread_message_count + 1 : 1;
            $conversation->last_message_id = $message->id;
            $conversation->last_message_time = now()->toDateTimeString();
            $conversation->save();

            $messageId = $message->id;
            $conversationId = $conversation->id;

            \Illuminate\Support\Facades\DB::table('foxgo_support_case_actions')->insert([
                'case_id' => $supportCase->id,
                'admin_id' => $admin->id,
                'department_id' => $supportCase->current_department_id,
                'action_type' => 'nina_customer_message_sent',
                'description' => 'Resposta sugerida pela Nina Atendente enviada manualmente ao cliente no chat nativo.',
                'old_value' => null,
                'new_value' => 'message_id:' . $message->id,
                'metadata' => json_encode([
                    'phase' => 'nina_v3d_store_nativo_6ammart',
                    'manual_human_approval' => true,
                    'target' => 'customer',
                    'conversation_id' => $conversation->id,
                    'message_id' => $message->id,
                    'sender_user_info_id' => $sender->id,
                    'receiver_user_info_id' => $receiver->id,
                    'message_sent' => true,
                    'no_order_action' => true,
                    'no_refund_action' => true,
                    'no_payment_gateway_action' => true,
                    'no_repasses_action' => true,
                ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        });

        return redirect()
            ->route('admin.support.cases.show', $supportCase->id)
            ->with('success', 'Resposta sugerida pela Nina enviada ao cliente no chat nativo.');
    }


}
