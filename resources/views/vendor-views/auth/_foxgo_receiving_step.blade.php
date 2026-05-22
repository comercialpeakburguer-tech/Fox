{{-- Fox GO - Etapa Dados de recebimento do lojista - versão limpa --}}
@php
    $foxgoWithdrawalMethods = \App\Models\WithdrawalMethod::where('is_active', 1)
        ->orderByDesc('is_default')
        ->orderBy('id')
        ->get();

    $foxgoDefaultMethod = $foxgoWithdrawalMethods->firstWhere('is_default', 1) ?? $foxgoWithdrawalMethods->first();
    $foxgoDefaultMethodId = old('withdraw_method_id', optional($foxgoDefaultMethod)->id);

    $foxgoPackageCount = isset($packages) && is_countable($packages) ? count($packages) : 0;
    $foxgoHasCommissionPlan = \App\CentralLogics\Helpers::commission_check();
    $foxgoShouldSkipBusinessPlan = $foxgoHasCommissionPlan && $foxgoPackageCount < 1;

    $foxgoBanks = [
        '001' => 'Banco do Brasil',
        '033' => 'Santander',
        '104' => 'Caixa Econômica Federal',
        '237' => 'Bradesco',
        '341' => 'Itaú',
        '260' => 'Nubank',
        '077' => 'Inter',
        '336' => 'C6 Bank',
        '290' => 'PagBank',
        '323' => 'Mercado Pago',
        '380' => 'PicPay',
        '756' => 'Sicoob',
        '748' => 'Sicredi',
        '422' => 'Banco Safra',
        '655' => 'Banco BV',
        '212' => 'Banco Original',
        '041' => 'Banrisul',
        '389' => 'Banco Mercantil do Brasil',
    ];
@endphp

@if($foxgoWithdrawalMethods->count())
<div class="d-none" id="foxgo-receiving-step" data-skip-business-plan="{{ $foxgoShouldSkipBusinessPlan ? '1' : '0' }}">
    <div class="card __card mb-3">
        <div class="card-header border-0">
            <h5 class="card-title text-center mb-0">Dados de recebimento</h5>
        </div>

        <div class="card-body p-4">
            <div class="card __card bg-F8F9FC mb-3">
                <div class="card-body p-4">
                    <p class="text-muted mb-4">
                        Informe como a loja deseja receber os repasses da Fox GO.
                    </p>

                    <div class="mb-4 p-3 rounded" style="background:#f8fafc;border:1px solid #e5e7eb;">
                        <h6 class="mb-2">Endereço e validação do responsável</h6>
                        <p class="text-muted mb-3" style="font-size:13px;">
                            A Fox GO usa esses dados para preparar a conta de recebimento com segurança, usando Pagar.me quando aplicável.
                        </p>

                        <div class="row g-3">
                            <div class="col-md-8">
                                <label class="form-label">Endereço residencial do responsável <span class="text-danger">*</span></label>
                                <input type="text" name="foxgo_representative_address_line1" class="form-control foxgo-receiving-input" placeholder="Nome da rua/avenida, sem número" required>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">Número <span class="text-danger">*</span></label>
                                <input type="text" name="address_street_number" class="form-control foxgo-receiving-input" placeholder="Ex.: 123" required>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">Bairro <span class="text-danger">*</span></label>
                                <input type="text" name="address_neighborhood" class="form-control foxgo-receiving-input" placeholder="Bairro" required>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">Complemento <span class="text-danger">*</span></label>
                                <input type="text" name="address_complementary" class="form-control foxgo-receiving-input" placeholder="Casa, loja, sala ou Sem complemento" required>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">Ponto de referência <span class="text-danger">*</span></label>
                                <input type="text" name="address_reference_point" class="form-control foxgo-receiving-input" placeholder="Próximo a..." required>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">CEP <span class="text-danger">*</span></label>
                                <input type="text" name="foxgo_representative_address_postal_code" class="form-control foxgo-receiving-input" placeholder="00000-000" maxlength="9" required>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Cidade <span class="text-danger">*</span></label>
                                <input type="text" name="foxgo_representative_address_city" class="form-control foxgo-receiving-input" placeholder="São Paulo" required>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">Estado/UF <span class="text-danger">*</span></label>
                                <input type="text" name="foxgo_representative_address_state" class="form-control foxgo-receiving-input" placeholder="SP" maxlength="2" required>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">Faturamento mensal estimado <span class="text-danger">*</span></label>
                                <input type="text" name="foxgo_monthly_estimated_revenue" class="form-control foxgo-receiving-input" placeholder="Ex.: 10000" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Razão social ou nome completo <span class="text-danger">*</span></label>
                                <input type="text" name="razao_social" class="form-control foxgo-receiving-input" placeholder="Razão social conforme CNPJ ou nome completo" required>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Tipo jurídico <span class="text-danger">*</span></label>
                                <input type="text" name="corporation_type" class="form-control foxgo-receiving-input" placeholder="Ex.: MEI, ME, LTDA ou autônomo" required>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Pessoa politicamente exposta? <span class="text-danger">*</span></label>
                                <select name="foxgo_political_exposure" class="form-control foxgo-receiving-input" required>
                                    <option value="none" selected>Não</option>
                                    <option value="existing">Sim</option>
                                </select>
                            </div>

                            <div class="col-md-6 d-flex align-items-end">
                                <label class="d-flex align-items-start gap-2 mb-0" style="font-size:13px;">
                                    <input type="checkbox" name="foxgo_stripe_terms_accepted" value="1" required style="margin-top:3px;">
                                    <span>Confirmo que os dados são verdadeiros e aceito os termos de recebimento da Fox GO.</span>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="mb-4 p-3 rounded" style="background:#f8fafc;border:1px solid #e5e7eb;">
                        <h6 class="mb-2">Responsável pelo recebimento</h6>
                        <p class="text-muted mb-3" style="font-size:13px;">
                            Esses dados precisam bater com o documento enviado.
                        </p>

                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">CPF do responsável <span class="text-danger">*</span></label>
                                <input type="text" name="foxgo_representative_cpf" id="foxgo_representative_cpf" class="form-control foxgo-receiving-input" placeholder="000.000.000-00" maxlength="14" required>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Data de nascimento <span class="text-danger">*</span></label>
                                <input type="date" name="foxgo_representative_birth_date" id="foxgo_representative_birth_date" class="form-control foxgo-receiving-input" required max="{{ now()->subYears(18)->format('Y-m-d') }}">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Profissão do responsável <span class="text-danger">*</span></label>
                                <input type="text" name="professional_occupation" class="form-control foxgo-receiving-input" placeholder="Ex.: Empresário, autônomo, comerciante" required>
                            </div>
                        </div>
                    </div>

                    <div class="mb-4 p-3 rounded" style="background:#fff7ed;border:1px solid #fed7aa;">
                        <h6 class="mb-2">Documento do responsável</h6>
                        <p class="text-muted mb-3" style="font-size:13px;">
                            Envie um documento oficial com foto do responsável. A Fox GO usa esse documento para verificação da conta de recebimento quando exigido pelo provedor de pagamento.
                        </p>

                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Documento do responsável <span class="text-danger">*</span></label>
                                <input type="file" name="foxgo_identity_document_front" class="form-control foxgo-receiving-input" accept=".pdf,.jpg,.jpeg,.png" required>
                                <small class="text-muted">RG, CNH ou documento oficial. PDF, JPG ou PNG até 10 MB.</small>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Verso do documento, se houver</label>
                                <input type="file" name="foxgo_identity_document_back" class="form-control foxgo-receiving-input" accept=".pdf,.jpg,.jpeg,.png">
                                <small class="text-muted">Use este campo se o documento tiver frente e verso.</small>
                            </div>
                        </div>
                    </div>

                    <div class="form-group mb-3">
                        <label class="form-label">Método de recebimento <span class="text-danger">*</span></label>
                        <select name="withdraw_method_id" id="foxgo_withdraw_method_id" class="form-control foxgo-receiving-input" required disabled>
                            @foreach($foxgoWithdrawalMethods as $method)
                                <option value="{{ $method->id }}" {{ (string)$foxgoDefaultMethodId === (string)$method->id ? 'selected' : '' }}>
                                    {{ $method->method_name }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    @foreach($foxgoWithdrawalMethods as $method)
                        @php
                            $methodFields = is_string($method->method_fields) ? json_decode($method->method_fields, true) : $method->method_fields;
                            $methodFields = is_array($methodFields) ? $methodFields : [];
                            $isCurrentMethod = (string)$foxgoDefaultMethodId === (string)$method->id;
                        @endphp

                        <div class="foxgo-withdraw-fields" data-method-id="{{ $method->id }}" style="{{ $isCurrentMethod ? '' : 'display:none' }}">
                            <div class="row g-3">
                                @foreach($methodFields as $field)
                                    @php
                                        $fieldName = $field['input_name'] ?? '';
                                        $fieldPlaceholder = $field['placeholder'] ?? $fieldName;
                                        $fieldRequired = !empty($field['is_required']);
                                    @endphp

                                    @if($fieldName)
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">
                                                    {{ $fieldPlaceholder }}
                                                    @if($fieldRequired)
                                                        <span class="text-danger">*</span>
                                                    @endif
                                                </label>

                                                @if($fieldName === 'codigo_banco')
                                                    <select name="codigo_banco" class="form-control foxgo-receiving-input foxgo-bank-code" data-required="{{ $fieldRequired ? '1' : '0' }}" disabled>
                                                        <option value="">Selecione o banco</option>
                                                        @foreach($foxgoBanks as $code => $name)
                                                            <option value="{{ $code }}">{{ $code }} - {{ $name }}</option>
                                                        @endforeach
                                                    </select>
                                                @elseif($fieldName === 'banco')
                                                    <input type="text" name="banco" class="form-control foxgo-receiving-input foxgo-bank-name" data-required="{{ $fieldRequired ? '1' : '0' }}" placeholder="Preenchido automaticamente" readonly disabled>
                                                @elseif($fieldName === 'tipo_de_conta')
                                                    <select name="tipo_de_conta" class="form-control foxgo-receiving-input" data-required="{{ $fieldRequired ? '1' : '0' }}" disabled>
                                                        <option value="">Selecione o tipo de conta</option>
                                                        <option value="corrente">Conta corrente</option>
                                                        <option value="poupanca">Conta poupança</option>
                                                    </select>
                                                @elseif($fieldName === 'tipo_documento_titular')
                                                    <select name="tipo_documento_titular" class="form-control foxgo-receiving-input foxgo-holder-doc-type" data-required="{{ $fieldRequired ? '1' : '0' }}" disabled>
                                                        <option value="">Selecione</option>
                                                        <option value="cpf">CPF</option>
                                                        <option value="cnpj">CNPJ</option>
                                                    </select>
                                                @else
                                                    <input type="text" name="{{ $fieldName }}" class="form-control foxgo-receiving-input" data-required="{{ $fieldRequired ? '1' : '0' }}" placeholder="{{ $fieldPlaceholder }}" value="{{ old($fieldName) }}" disabled>
                                                @endif
                                            </div>
                                        </div>
                                    @endif
                                @endforeach
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>

            <div class="text-end pt-5 d-flex flex-wrap p-4 justify-content-end gap-3">
                <button type="button" id="foxgo-back-to-general" class="cmn--btn btn--secondary shadow-none rounded-md border-0 outline-0">
                    {{ translate('Back') }}
                </button>
                <button type="button" id="foxgo-next-to-business" class="cmn--btn rounded-md border-0 outline-0">
                    {{ translate('Next') }}
                </button>
            </div>
        </div>
    </div>
</div>

<script>
(function () {
    "use strict";

    window.foxgoReceivingCompleted = false;

    const banks = @json($foxgoBanks);

    function el(id) {
        return document.getElementById(id);
    }

    function onlyDigits(value) {
        return String(value || '').replace(/\D+/g, '');
    }

    function showError(message) {
        if (window.toastr) {
            toastr.error(message);
        } else {
            alert(message);
        }
    }

    function setStep(step) {
        document.querySelectorAll(".stepper-item").forEach(function (item) {
            item.classList.remove("active");
        });

        if (step === "general" && el("show-step1")) el("show-step1").classList.add("active");
        if (step === "receiving" && el("show-step-receiving")) el("show-step-receiving").classList.add("active");
        if (step === "business" && el("show-step2")) el("show-step2").classList.add("active");
    }

    function ensureCommissionPlanInput() {
        let input = document.querySelector('input[name="business_plan"][value="commission-base"]');

        if (input) {
            input.checked = true;
            input.disabled = false;
            return;
        }

        input = document.createElement("input");
        input.type = "hidden";
        input.name = "business_plan";
        input.value = "commission-base";

        if (el("form-id")) {
            el("form-id").appendChild(input);
        }
    }

    function enableSelectedFields() {
        const step = el("foxgo-receiving-step");
        const select = el("foxgo_withdraw_method_id");

        if (!step || !select) return;

        const visible = !step.classList.contains("d-none");
        const selected = String(select.value || "");

        select.disabled = !visible;

        document.querySelectorAll(".foxgo-withdraw-fields").forEach(function (group) {
            const active = visible && String(group.getAttribute("data-method-id")) === selected;
            group.style.display = active ? "" : "none";

            group.querySelectorAll("input, select, textarea").forEach(function (field) {
                field.disabled = !active;

                if (active && field.getAttribute("data-required") === "1") {
                    field.setAttribute("required", "required");
                } else {
                    field.removeAttribute("required");
                    field.classList.remove("is-invalid");
                }
            });
        });

        updateBankName();
    }

    function updateBankName() {
        const code = document.querySelector(".foxgo-bank-code");
        const name = document.querySelector(".foxgo-bank-name");

        if (!code || !name) return;

        name.value = banks[code.value] || "";
    }

    function validateField(field) {
        if (!field || field.disabled) return true;

        let ok = true;
        const type = String(field.type || '').toLowerCase();

        if (field.required) {
            if (type === 'file') {
                ok = field.files && field.files.length > 0;
            } else if (type === 'checkbox') {
                ok = field.checked;
            } else {
                ok = String(field.value || '').trim() !== '';
            }
        }

        if (!ok) {
            field.classList.add("is-invalid");
        } else {
            field.classList.remove("is-invalid");
        }

        return ok;
    }

    function receivingValid() {
        const step = el("foxgo-receiving-step");

        if (!step || step.classList.contains("d-none")) {
            return true;
        }

        enableSelectedFields();

        let valid = true;

        step.querySelectorAll(".foxgo-receiving-input[required], input[name='foxgo_stripe_terms_accepted'][required]").forEach(function (field) {
            if (!validateField(field)) {
                valid = false;
            }
        });

        const selected = String((el("foxgo_withdraw_method_id") || {}).value || "");
        document.querySelectorAll('.foxgo-withdraw-fields[data-method-id="' + selected + '"] [data-required="1"]').forEach(function (field) {
            if (!validateField(field)) {
                valid = false;
            }
        });

        const cpf = document.querySelector("[name='foxgo_representative_cpf']");
        if (cpf && !cpf.disabled && onlyDigits(cpf.value).length !== 11) {
            cpf.classList.add("is-invalid");
            valid = false;
        }

        const cep = document.querySelector("[name='foxgo_representative_address_postal_code']");
        if (cep && !cep.disabled && onlyDigits(cep.value).length !== 8) {
            cep.classList.add("is-invalid");
            valid = false;
        }

        if (!valid) {
            showError("Preencha todos os dados de recebimento obrigatórios antes de continuar.");
            const firstInvalid = step.querySelector(".is-invalid");
            if (firstInvalid) {
                firstInvalid.scrollIntoView({behavior: "smooth", block: "center"});
                setTimeout(function () { firstInvalid.focus({preventScroll: true}); }, 300);
            }
        }

        return valid;
    }

    window.foxgoReceivingEnableSelected = enableSelectedFields;
    window.foxgoReceivingValid = receivingValid;

    window.foxgoShouldBlockSubmitBeforeReceiving = function () {
        return !window.foxgoReceivingCompleted;
    };

    window.foxgoOpenReceivingStep = function () {
        const general = el("reg-form-div");
        const receiving = el("foxgo-receiving-step");
        const business = el("business-plan-div");

        window.foxgoReceivingCompleted = false;

        if (general) {
            general.classList.add("d-none");
            general.style.display = "none";
        }

        if (business) {
            business.classList.add("d-none");
            business.style.display = "none";
        }

        if (receiving) {
            receiving.classList.remove("d-none");
            receiving.style.display = "";
        }

        setStep("receiving");
        enableSelectedFields();
        window.scrollTo({top: 0, behavior: "smooth"});
    };

    window.foxgoOpenBusinessPlanAfterReceiving = function () {
        const receiving = el("foxgo-receiving-step");
        const business = el("business-plan-div");
        const skipBusiness = receiving && receiving.getAttribute("data-skip-business-plan") === "1";

        if (!receivingValid()) return;

        window.foxgoReceivingCompleted = true;
        enableSelectedFields();

        if (skipBusiness) {
            ensureCommissionPlanInput();
            $("#form-id").trigger("submit");
            return;
        }

        if (receiving) {
            receiving.classList.add("d-none");
            receiving.style.display = "none";
        }

        if (business) {
            business.classList.remove("d-none");
            business.style.display = "";
        }

        setStep("business");
        ensureCommissionPlanInput();
        window.scrollTo({top: 0, behavior: "smooth"});
    };

    document.addEventListener("DOMContentLoaded", function () {
        const select = el("foxgo_withdraw_method_id");
        const back = el("foxgo-back-to-general");
        const next = el("foxgo-next-to-business");

        if (select) {
            select.addEventListener("change", enableSelectedFields);
        }

        document.addEventListener("change", function (event) {
            if (event.target && event.target.classList.contains("foxgo-bank-code")) {
                updateBankName();
            }
        });

        document.addEventListener("input", function (event) {
            const field = event.target;
            if (!field) return;

            if (field.name === "foxgo_representative_cpf" || field.name === "documento_titular" || field.name === "chave") {
                field.value = onlyDigits(field.value);
            }

            if (field.name === "foxgo_representative_address_postal_code" || field.name === "agencia" || field.name === "conta" || field.name === "digito") {
                field.value = onlyDigits(field.value);
            }
        });

        if (back) {
            back.addEventListener("click", function () {
                const general = el("reg-form-div");
                const receiving = el("foxgo-receiving-step");

                window.foxgoReceivingCompleted = false;

                if (receiving) {
                    receiving.classList.add("d-none");
                    receiving.style.display = "none";
                }

                if (general) {
                    general.classList.remove("d-none");
                    general.style.display = "";
                }

                setStep("general");
                enableSelectedFields();
                window.scrollTo({top: 0, behavior: "smooth"});
            });
        }

        if (next) {
            next.addEventListener("click", function () {
                window.foxgoOpenBusinessPlanAfterReceiving();
            });
        }

        enableSelectedFields();
    });
})();
</script>
@endif
