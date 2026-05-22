<?php

namespace App\Http\Controllers;

use App\Models\Zone;
use App\Models\Admin;
use App\Models\Store;
use App\Models\Module;
use App\Models\Vendor;
use App\Models\WithdrawalMethod;
use Illuminate\Http\Request;
use App\CentralLogics\Helpers;
use App\Mail\StoreRegistration;
use App\Models\BusinessSetting;
use App\CentralLogics\StoreLogic;
use App\CentralLogics\FoxGoStripeConnectOnboardingLogic;
use App\CentralLogics\FoxGoStripeConnectApiOnboardingLogic;
use Illuminate\Http\JsonResponse;
use App\Models\SubscriptionPackage;
use Gregwar\Captcha\CaptchaBuilder;
use App\Mail\VendorSelfRegistration;
use App\Models\ModuleZone;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;
use MatanYadaev\EloquentSpatial\Objects\Point;
use Modules\Rental\Emails\ProviderRegistration;
use Modules\Rental\Emails\ProviderSelfRegistration;

class VendorController extends Controller
{
    public function create()
    {
        $status = Helpers::get_business_settings ('toggle_store_registration');
        if(!isset($status) || $status == '0')
        {
            Toastr::error(translate('messages.not_found'));
            return back();
        }
        $admin_commission= Helpers::get_business_settings ('admin_commission');
        $business_name= Helpers::get_business_settings ('business_name');
        $packages= SubscriptionPackage::where('status',1)->where('module_type', 'all')->latest()->get();
        $custome_recaptcha = new CaptchaBuilder;
        $custome_recaptcha->build();
        Session::put('six_captcha', $custome_recaptcha->getPhrase());

        return view('vendor-views.auth.general-info', compact('custome_recaptcha','admin_commission','business_name','packages' ));
    }

    public function store(Request $request)
    {
        $validator = Validator::make([], []);
        $status = Helpers::get_business_settings ('toggle_store_registration');
        if(!isset($status) || $status == '0')
        {
            $validator->getMessageBag()->add('latitude', translate('messages.not_found'));
            return response()->json(['errors' => Helpers::error_processor($validator)]);

        }

        $recaptcha = Helpers::get_business_settings('recaptcha');
        // Fox GO - reCAPTCHA retorna JSON no cadastro lojista
        if (isset($recaptcha) && $recaptcha['status'] == 1) {
            $recaptchaValidator = Validator::make($request->all(), [
                'g-recaptcha-response' => [
                    function ($attribute, $value, $fail) use ($recaptcha) {
                        $secret_key = $recaptcha['secret_key'];

                        $gResponse = Http::asForm()->post('https://www.google.com/recaptcha/api/siteverify', [
                            'secret' => $secret_key,
                            'response' => $value,
                            'remoteip' => request()->ip(),
                        ]);

                        if (!$gResponse->successful()) {
                            $fail(translate('ReCaptcha Failed'));
                            return;
                        }

                        $result = $gResponse->json();
                        if (empty($result['success'])) {
                            $fail(translate('ReCaptcha Failed'));
                        }
                    },
                ],
            ]);

            if ($recaptchaValidator->fails()) {
                return response()->json(['errors' => Helpers::error_processor($recaptchaValidator)]);
            }
        }

        // Fox GO - quando o reCAPTCHA está desativado no painel, não bloquear o cadastro
        // pelo captcha custom antigo do 6amMart. Na pré-publicação, configurar Google reCAPTCHA real se necessário.

        $validator = Validator::make($request->all(), [
            'f_name' => 'required',
            'name' => 'required',
            'address' => 'required',
            'latitude' => 'required',
            'longitude' => 'required',
            'email' => 'required|unique:vendors',
            'phone' => 'required|regex:/^([0-9\s\-\+\(\)]*)$/|min:10|unique:vendors',
            'minimum_delivery_time' => 'required',
            'maximum_delivery_time' => 'required',
            'password' => ['required', Password::min(8)->mixedCase()->letters()->numbers()->symbols()],
            'zone_id' => 'required',
            'module_id' => 'required',
            'logo' => 'required|image|max:2048|mimes:'.IMAGE_FORMAT_FOR_VALIDATION,
            'cover_photo' => 'nullable|image|max:2048|mimes:'.IMAGE_FORMAT_FOR_VALIDATION,
            'delivery_time_type'=>'required',
        ],[
            'password.min_length' => translate('The password must be at least :min characters long'),
            'password.mixed' => translate('The password must contain both uppercase and lowercase letters'),
            'password.letters' => translate('The password must contain letters'),
            'password.numbers' => translate('The password must contain numbers'),
            'password.symbols' => translate('The password must contain symbols'),
            'password.uncompromised' => translate('The password is compromised. Please choose a different one'),
            'password.custom' => translate('The password cannot contain white spaces.'),
        ]);
        if ($validator->fails()) {
                 return response()->json(['errors' => Helpers::error_processor($validator)]);
        }
        // Fox GO - bloqueio final de email duplicado antes de criar loja
        $foxgoVendorApplyEmail = strtolower(trim((string) $request->email));
        if ($foxgoVendorApplyEmail !== '') {
            $foxgoEmailAlreadyExists =
                \App\Models\Vendor::whereRaw('LOWER(email) = ?', [$foxgoVendorApplyEmail])->exists()
                || \App\Models\Store::whereRaw('LOWER(email) = ?', [$foxgoVendorApplyEmail])->exists();

            if ($foxgoEmailAlreadyExists) {
                $validator->getMessageBag()->add('email', 'Este e-mail já está cadastrado. Use outro e-mail.');
                return response()->json(['errors' => Helpers::error_processor($validator)]);
            }
        }


        // Fox GO - comprovante CNPJ/CCMEI obrigatório
        if (!$request->hasFile('tin_certificate_image')) {
            $validator->getMessageBag()->add('tin_certificate_image', 'Envie o comprovante do CNPJ ou CCMEI da loja.');
            return response()->json(['errors' => Helpers::error_processor($validator)]);
        }

        // Fox GO - valida dados de recebimento do lojista
        $withdrawal_method = WithdrawalMethod::where('id', $request->withdraw_method_id)->where('is_active', 1)->first();
        if (!$withdrawal_method) {
            $validator->getMessageBag()->add('withdraw_method_id', 'Selecione um método de recebimento válido.');
            return response()->json(['errors' => Helpers::error_processor($validator)]);
        }

        
        
        // Fox GO - valida dados bancários com selects Brasil
        $foxgoWithdrawalNameForBank = strtolower((string)($withdrawal_method->method_name ?? ''));

        if ($foxgoWithdrawalNameForBank === 'banco') {
            $foxgoAllowedBanks = [
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
                '655' => 'Banco Votorantim/BV',
                '212' => 'Banco Original',
                '041' => 'Banrisul',
                '389' => 'Banco Mercantil do Brasil',
            ];

            $foxgoBankCode = str_pad(preg_replace('/\D+/', '', (string) $request->codigo_banco), 3, '0', STR_PAD_LEFT);
            $foxgoAgency = preg_replace('/\D+/', '', (string) $request->agencia);
            $foxgoAccount = preg_replace('/\D+/', '', (string) $request->conta);
            $foxgoDigit = preg_replace('/\D+/', '', (string) $request->digito);
            $foxgoAccountType = strtolower(trim((string) $request->tipo_de_conta));
            $foxgoHolder = trim((string) $request->titular);
            $foxgoHolderDocType = strtolower(trim((string) $request->tipo_documento_titular));
            $foxgoHolderDoc = preg_replace('/\D+/', '', (string) $request->documento_titular);

            $foxgoCpfIsValidForBank = function ($cpf) {
                $cpf = preg_replace('/\D+/', '', (string) $cpf);

                if (strlen($cpf) !== 11 || preg_match('/^(\d)\1{10}$/', $cpf)) {
                    return false;
                }

                for ($t = 9; $t < 11; $t++) {
                    $d = 0;
                    for ($c = 0; $c < $t; $c++) {
                        $d += intval($cpf[$c]) * (($t + 1) - $c);
                    }

                    $d = ((10 * $d) % 11) % 10;

                    if (intval($cpf[$c]) !== $d) {
                        return false;
                    }
                }

                return true;
            };

            if (!isset($foxgoAllowedBanks[$foxgoBankCode])) {
                $validator->getMessageBag()->add('codigo_banco', 'Selecione um banco válido da lista.');
            }

            if (strlen($foxgoAgency) < 3 || strlen($foxgoAgency) > 5) {
                $validator->getMessageBag()->add('agencia', 'Informe a agência corretamente, sem dígito.');
            }

            if (strlen($foxgoAccount) < 3) {
                $validator->getMessageBag()->add('conta', 'Informe o número da conta corretamente.');
            }

            if (!in_array($foxgoAccountType, ['corrente', 'poupanca', 'poupança'], true)) {
                $validator->getMessageBag()->add('tipo_de_conta', 'Selecione conta corrente ou poupança.');
            }

            if ($foxgoHolder === '') {
                $validator->getMessageBag()->add('titular', 'Informe o nome do titular igual ao banco.');
            }

            if (!in_array($foxgoHolderDocType, ['cpf', 'cnpj'], true)) {
                $validator->getMessageBag()->add('tipo_documento_titular', 'Selecione se o titular usa CPF ou CNPJ.');
            } elseif ($foxgoHolderDocType === 'cpf') {
                if (!$foxgoCpfIsValidForBank($foxgoHolderDoc)) {
                    $validator->getMessageBag()->add('documento_titular', 'Informe um CPF válido do titular.');
                }
            } elseif ($foxgoHolderDocType === 'cnpj') {
                if (!\App\CentralLogics\FoxGoCnpjValidationLogic::isValidCnpj($foxgoHolderDoc)) {
                    $validator->getMessageBag()->add('documento_titular', 'Informe um CNPJ válido do titular.');
                }
            }

            if ($validator->errors()->count() > 0) {
                return response()->json(['errors' => Helpers::error_processor($validator)]);
            }

            $request->merge([
                'codigo_banco' => $foxgoBankCode,
                'banco' => $foxgoAllowedBanks[$foxgoBankCode] ?? $request->banco,
                'agencia' => $foxgoAgency,
                'conta' => $foxgoAccount,
                'digito' => $foxgoDigit,
                'tipo_de_conta' => $foxgoAccountType === 'poupança' ? 'poupanca' : $foxgoAccountType,
                'tipo_documento_titular' => $foxgoHolderDocType,
                'documento_titular' => $foxgoHolderDoc,
            ]);
        }
// Fox GO - Pix somente CPF do responsável ou CNPJ da loja
        $foxgoWithdrawalName = strtolower((string)($withdrawal_method->method_name ?? ''));

        if ($foxgoWithdrawalName === 'pix') {
            $foxgoPixKey = preg_replace('/\D+/', '', (string) $request->chave);
            $foxgoRepresentativeCpfForPix = preg_replace('/\D+/', '', (string) $request->foxgo_representative_cpf);
            $foxgoStoreCnpjForPix = preg_replace('/\D+/', '', (string) $request->tin);

            $foxgoCpfIsValid = function ($cpf) {
                $cpf = preg_replace('/\D+/', '', (string) $cpf);

                if (strlen($cpf) !== 11 || preg_match('/^(\d)\1{10}$/', $cpf)) {
                    return false;
                }

                for ($t = 9; $t < 11; $t++) {
                    $d = 0;
                    for ($c = 0; $c < $t; $c++) {
                        $d += intval($cpf[$c]) * (($t + 1) - $c);
                    }

                    $d = ((10 * $d) % 11) % 10;

                    if (intval($cpf[$c]) !== $d) {
                        return false;
                    }
                }

                return true;
            };

            if (!(strlen($foxgoPixKey) === 11 || strlen($foxgoPixKey) === 14)) {
                $validator->getMessageBag()->add('chave', 'A chave Pix deve ser CPF do responsável ou CNPJ da loja. Não aceitamos e-mail, celular ou chave aleatória.');
            } elseif (strlen($foxgoPixKey) === 11) {
                if (!$foxgoCpfIsValid($foxgoPixKey)) {
                    $validator->getMessageBag()->add('chave', 'Informe um CPF válido como chave Pix.');
                } elseif ($foxgoRepresentativeCpfForPix && $foxgoPixKey !== $foxgoRepresentativeCpfForPix) {
                    $validator->getMessageBag()->add('chave', 'A chave Pix CPF precisa ser o mesmo CPF do responsável pelo recebimento.');
                }
            } elseif (strlen($foxgoPixKey) === 14) {
                if (!\App\CentralLogics\FoxGoCnpjValidationLogic::isValidCnpj($foxgoPixKey)) {
                    $validator->getMessageBag()->add('chave', 'Informe um CNPJ válido como chave Pix.');
                } elseif ($foxgoStoreCnpjForPix && $foxgoPixKey !== $foxgoStoreCnpjForPix) {
                    $validator->getMessageBag()->add('chave', 'A chave Pix CNPJ precisa ser o mesmo CNPJ da loja.');
                }
            }

            if ($validator->errors()->count() > 0) {
                return response()->json(['errors' => Helpers::error_processor($validator)]);
            }

            $request->merge(['chave' => $foxgoPixKey]);
        }
// Fox GO - valida CPF e nascimento do responsável para Stripe Connect
        $foxgoRepresentativeCpf = preg_replace('/\D+/', '', (string) $request->foxgo_representative_cpf);
        if (strlen($foxgoRepresentativeCpf) !== 11) {
            $validator->getMessageBag()->add('foxgo_representative_cpf', 'Informe o CPF do responsável pela loja.');
        }

        if (!$request->filled('foxgo_representative_birth_date')) {
            $validator->getMessageBag()->add('foxgo_representative_birth_date', 'Informe a data de nascimento do responsável pela loja.');
        }

        // Fox GO - valida nascimento real e maioridade do responsável antes de chamar a Stripe
        if ($request->filled('foxgo_representative_birth_date')) {
            try {
                $foxgoBirthDate = new \DateTime($request->foxgo_representative_birth_date);
                $foxgoToday = new \DateTime('today');
                $foxgoAge = $foxgoBirthDate->diff($foxgoToday)->y;

                if ($foxgoBirthDate >= $foxgoToday) {
                    $validator->getMessageBag()->add('foxgo_representative_birth_date', 'A data de nascimento precisa estar no passado.');
                } elseif ($foxgoAge < 18) {
                    $validator->getMessageBag()->add('foxgo_representative_birth_date', 'O responsável pelo recebimento precisa ser maior de 18 anos.');
                }
            } catch (\Throwable $e) {
                $validator->getMessageBag()->add('foxgo_representative_birth_date', 'Informe uma data de nascimento válida.');
            }
        }

        
        // Fox GO - documento do responsável obrigatório para Stripe API onboarding
        $foxgoAllowedIdentityExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
        $foxgoMaxIdentitySize = 10 * 1024 * 1024;

        if (!$request->hasFile('foxgo_identity_document_front')) {
            $validator->getMessageBag()->add('foxgo_identity_document_front', 'Envie o documento do responsável pela loja.');
        }

        foreach (['foxgo_identity_document_front', 'foxgo_identity_document_back'] as $foxgoIdentityFileField) {
            if ($request->hasFile($foxgoIdentityFileField)) {
                $foxgoFile = $request->file($foxgoIdentityFileField);
                $foxgoExt = strtolower((string) $foxgoFile->getClientOriginalExtension());

                if (!in_array($foxgoExt, $foxgoAllowedIdentityExtensions, true)) {
                    $validator->getMessageBag()->add($foxgoIdentityFileField, 'O documento deve estar em PDF, JPG ou PNG.');
                }

                if ($foxgoFile->getSize() > $foxgoMaxIdentitySize) {
                    $validator->getMessageBag()->add($foxgoIdentityFileField, 'O documento deve ter no máximo 10 MB.');
                }
            }
        }

        if ($validator->errors()->count() > 0) {
            return response()->json(['errors' => Helpers::error_processor($validator)]);
        }

        // Fox GO - valida dados completos para API onboarding Stripe Connect
        $foxgoRequiredApiOnboardingFields = [
            'foxgo_representative_address_line1' => 'Informe o endereço residencial do responsável.',
            'foxgo_representative_address_city' => 'Informe a cidade do responsável.',
            'foxgo_representative_address_state' => 'Informe o estado/UF do responsável.',
            'foxgo_representative_address_postal_code' => 'Informe o CEP do responsável.',
            'foxgo_monthly_estimated_revenue' => 'Informe o faturamento mensal estimado.',
              'razao_social' => 'Informe a razão social ou nome completo do titular.',
              'corporation_type' => 'Informe o tipo jurídico.',
              'address_street_number' => 'Informe o número do endereço.',
              'address_neighborhood' => 'Informe o bairro.',
              'address_complementary' => 'Informe o complemento. Se não houver, escreva Sem complemento.',
              'address_reference_point' => 'Informe um ponto de referência.',
              'professional_occupation' => 'Informe a profissão do responsável.',
            'foxgo_political_exposure' => 'Informe se o responsável é pessoa politicamente exposta.',
            'foxgo_stripe_terms_accepted' => 'Você precisa aceitar os termos de recebimento para continuar.',
        ];

        foreach ($foxgoRequiredApiOnboardingFields as $foxgoField => $foxgoMessage) {
            if (!$request->filled($foxgoField)) {
                $validator->getMessageBag()->add($foxgoField, $foxgoMessage);
            }
        }

        if ($validator->errors()->count() > 0) {
            return response()->json(['errors' => Helpers::error_processor($validator)]);
        }

        $withdrawal_method_fields = is_array($withdrawal_method->method_fields)
            ? $withdrawal_method->method_fields
            : json_decode($withdrawal_method->method_fields, true);

        $withdrawal_method_fields = is_array($withdrawal_method_fields) ? $withdrawal_method_fields : [];

        foreach ($withdrawal_method_fields as $field) {
            $field_name = $field['input_name'] ?? null;

            if ($field_name && !empty($field['is_required']) && !$request->filled($field_name)) {
                $validator->getMessageBag()->add($field_name, ($field['placeholder'] ?? $field_name) . ' é obrigatório.');
            }
        }

        if ($validator->errors()->count() > 0) {
            return response()->json(['errors' => Helpers::error_processor($validator)]);
        }

        if($request->zone_id)
        {
            $zone = Zone::query()
            ->whereContains('coordinates', new Point($request->latitude, $request->longitude, POINT_SRID))
            ->where('id',$request->zone_id)
            ->first();
            if(!$zone){
              $validator->getMessageBag()->add('zone', translate('coordinates_out_of_zone'));
                 return response()->json(['errors' => Helpers::error_processor($validator)]);
            }
        }

        $module = Module::find($request['module_id']);
        if ($module?->module_type == 'rental' && addon_published_status('Rental') && empty($request['pickup_zone_id'])){
            $validator->getMessageBag()->add('pickup_zone_id', translate('messages.You_must_select_a_pickup_zone'));
            return response()->json(['errors' => Helpers::error_processor($validator)]);
        }

        if ($request->business_plan == 'subscription-base' && $request->package_id == null ) {
            $validator->getMessageBag()->add('package_id', translate('messages.You_must_select_a_package'));
             return response()->json(['errors' => Helpers::error_processor($validator)]);
        }

        $vendor = new Vendor();
        $vendor->f_name = $request->f_name;
        $vendor->l_name = $request->l_name;
        $vendor->email = $request->email;
        $vendor->phone = $request->phone;
        $vendor->password = bcrypt($request->password);
        $vendor->status = null;
        $vendor->save();

        $store = new Store;
        $store->name =  $request->name[array_search('default', $request->lang)];
        $store->phone = $request->phone;
        $store->email = $request->email;
        $store->logo = Helpers::upload('store/', 'png', $request->file('logo'));
        $store->cover_photo = Helpers::upload('store/cover/', 'png', $request->file('cover_photo'));
        $store->address = $request->address[array_search('default', $request->lang)];
        $store->latitude = $request->latitude;
        $store->longitude = $request->longitude;
        $store->vendor_id = $vendor->id;
        $store->zone_id = $request->zone_id;
        $store->module_id = $request->module_id;
        $store->pickup_zone_id = json_encode($request['pickup_zone_id']?? []) ;
        $store->tin = $request->tin;
        $store->tin_expire_date = $request->tin_expire_date;
        $extension = $request->has('tin_certificate_image') ? $request->file('tin_certificate_image')->getClientOriginalExtension() : 'png';
        $store->tin_certificate_image = Helpers::upload('store/', $extension, $request->file('tin_certificate_image'));
        $store->delivery_time = $request->minimum_delivery_time .'-'. $request->maximum_delivery_time.' '.$request->delivery_time_type;
        $store->status = 0;
        $store->store_business_model = 'none';
        $store->save();

        // Fox GO - salva método de recebimento padrão do lojista
        $withdrawal_method_data = [];

        foreach ($withdrawal_method_fields as $field) {
            $field_name = $field['input_name'] ?? null;

            if ($field_name && $request->has($field_name)) {
                $withdrawal_method_data[$field_name] = $request->input($field_name);
            }
        }

        // Fox GO - inclui dados do responsável para prefill Stripe Connect


        $withdrawal_method_data['foxgo_representative_cpf'] = preg_replace('/\D+/', '', (string) $request->foxgo_representative_cpf);


        $withdrawal_method_data['foxgo_representative_birth_date'] = $request->foxgo_representative_birth_date;

        // Fox GO - salva campos completos para API onboarding Stripe Connect
        $withdrawal_method_data['foxgo_representative_address_line1'] = $request->foxgo_representative_address_line1;
        $withdrawal_method_data['foxgo_representative_address_city'] = $request->foxgo_representative_address_city;
        $withdrawal_method_data['foxgo_representative_address_state'] = strtoupper((string) $request->foxgo_representative_address_state);
        $withdrawal_method_data['foxgo_representative_address_postal_code'] = preg_replace('/\D+/', '', (string) $request->foxgo_representative_address_postal_code);
        $withdrawal_method_data['foxgo_monthly_estimated_revenue'] = $request->foxgo_monthly_estimated_revenue;
          $withdrawal_method_data['razao_social'] = $request->razao_social;
          $withdrawal_method_data['corporation_type'] = $request->corporation_type;
          $withdrawal_method_data['address_street_number'] = $request->address_street_number;
          $withdrawal_method_data['address_neighborhood'] = $request->address_neighborhood;
          $withdrawal_method_data['address_complementary'] = $request->address_complementary;
          $withdrawal_method_data['address_reference_point'] = $request->address_reference_point;
          $withdrawal_method_data['professional_occupation'] = $request->professional_occupation;
        $withdrawal_method_data['foxgo_political_exposure'] = $request->foxgo_political_exposure;
        $withdrawal_method_data['foxgo_stripe_terms_accepted'] = $request->filled('foxgo_stripe_terms_accepted') ? 1 : 0;



        DB::table('disbursement_withdrawal_methods')->where('store_id', $store->id)->update(['is_default' => 0]);

        DB::table('disbursement_withdrawal_methods')->insert([
            'store_id' => $store->id,
            'delivery_man_id' => null,
            'withdrawal_method_id' => $withdrawal_method->id,
            'method_name' => $withdrawal_method->method_name,
            'method_fields' => json_encode($withdrawal_method_data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),
            'is_default' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Fox GO Pagar.me - cria recipient local pending no cadastro, sem chamar API externa
        try {
            $foxgoDocDigits = preg_replace('/\D+/', '', (string)($withdrawal_method_data['documento_titular'] ?? $withdrawal_method_data['foxgo_representative_cpf'] ?? ''));
            $foxgoAccountDigits = preg_replace('/\D+/', '', (string)($withdrawal_method_data['conta'] ?? ''));
            $foxgoBankCode = preg_replace('/\D+/', '', (string)($withdrawal_method_data['codigo_banco'] ?? ''));

            DB::table('foxgo_pagarme_recipients')->updateOrInsert(
                [
                    'owner_type' => 'store',
                    'owner_id' => $store->id,
                    'environment' => 'live',
                ],
                [
                    'store_id' => $store->id,
                    'vendor_id' => $vendor->id,
                    'delivery_man_id' => null,
                    'recipient_id' => null,
                    'status' => 'pending',
                    'legal_name' => $withdrawal_method_data['titular'] ?? $store->name,
                    'document_type' => strlen($foxgoDocDigits) === 14 ? 'cnpj' : (strlen($foxgoDocDigits) === 11 ? 'cpf' : null),
                    'document_last4' => $foxgoDocDigits ? substr($foxgoDocDigits, -4) : null,
                    'bank_code' => $foxgoBankCode ?: null,
                    'bank_account_last4' => $foxgoAccountDigits ? substr($foxgoAccountDigits, -4) : null,
                    'transfer_enabled' => 0,
                    'split_enabled' => 0,
                    'last_sync_at' => null,
                    'metadata' => json_encode([
                        'source' => 'vendor_registration',
                        'created_without_pagarme_api_call' => true,
                        'withdrawal_method_id' => $withdrawal_method->id,
                        'method_name' => $withdrawal_method->method_name,
                    ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),
                    'error_message' => null,
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );
        } catch (\Throwable $e) {
            info('FoxGoPagarmeRecipientLocal: falha não bloqueante store_id=' . $store->id . ' erro=' . $e->getMessage());
        }

        // Fox GO Pagar.me - Stripe Connect automático desativado no cadastro.
        // Mantido apenas como legado técnico; novos lojistas seguem recipient local Pagar.me pending.
        info('FoxGoPagarmeRecipientLocal: Stripe Connect automático ignorado no cadastro store_id=' . $store->id);

        Helpers::add_or_update_translations(request: $request, key_data: 'name', name_field: 'name', model_name: 'Store', data_id: $store->id, data_value: $store->name);
        Helpers::add_or_update_translations(request: $request, key_data: 'address', name_field: 'address', model_name: 'Store', data_id: $store->id, data_value: $store->address);


        try{
            $admin= Admin::where('role_id', 1)->first();
            if($module?->module_type != 'rental' && config('mail.status') && Helpers::get_mail_status('registration_mail_status_store') == '1' &&  Helpers::getNotificationStatusData('store','store_registration','mail_status') ){
                Mail::to($request['email'])->send(new VendorSelfRegistration('pending', $vendor->f_name.' '.$vendor->l_name));
            }
            elseif($module?->module_type == 'rental' && addon_published_status('Rental')&& config('mail.status') && Helpers::get_mail_status('rental_registration_mail_status_provider') == '1' &&  Helpers::getRentalNotificationStatusData('provider','provider_registration','mail_status') ){
                Mail::to($request['email'])->send(new ProviderSelfRegistration('pending', $vendor->f_name.' '.$vendor->l_name));
            }

            if($module?->module_type != 'rental' && config('mail.status') && Helpers::get_mail_status('store_registration_mail_status_admin') == '1' &&  Helpers::getNotificationStatusData('admin','store_self_registration','mail_status') ){
                Mail::to($admin?->getRawOriginal('email'))->send(new StoreRegistration('pending', $vendor->f_name.' '.$vendor->l_name));
            } elseif($module?->module_type == 'rental' && addon_published_status('Rental')&& config('mail.status') && Helpers::get_mail_status('rental_provider_registration_mail_status_admin') == '1' &&  Helpers::getRentalNotificationStatusData('admin','provider_self_registration','mail_status') ){
                Mail::to($admin?->getRawOriginal('email'))->send(new ProviderRegistration('pending', $vendor->f_name.' '.$vendor->l_name));
            }

        }catch(\Exception $ex){
            info($ex->getMessage());
        }


        if(config('module.'.$store->module->module_type)['always_open'])
        {
            StoreLogic::insert_schedule($store->id);
        }

        if (Helpers::subscription_check()) {
            if ($request->business_plan == 'subscription-base' && $request->package_id != null ) {

                $store->package_id = $request->package_id;
                $store->save();

            }
            elseif($request->business_plan == 'commission-base' ){
                $store->store_business_model = 'commission';
                $store->save();

            }
        } else{
            $store->store_business_model = 'commission';
            $store->save();

        }

            // Fox GO - redirect final seguro do cadastro lojista
        $foxgoBusinessPlan = $request->business_plan ?: 'commission-base';
        $foxgoRedirectUrl = route('restaurant.secondStep', [
            'store_id' => $store->id,
            'business_plan' => $foxgoBusinessPlan,
        ]);

        return response()->json([
            'redirect_url' => $foxgoRedirectUrl,
            'store_id' => $store->id,
            'vendor_id' => $vendor->id,
            'business_plan' => $foxgoBusinessPlan,
        ]);

    }

    public function get_all_modules(Request $request){
        $module_data = Module::Active()->whereHas('zones', function($query)use ($request){
            $query->where('zone_id', $request->zone_id);
        })->notParcel()
        ->where('modules.module_name', 'like', '%'.$request->q.'%')
        ->limit(8)->get()->map(function($module) {
            return [
                'id' => $module->id,
                'text' => $module->module_name
            ];
        });
        return response()->json($module_data);
    }

    /**
     * @param Request $request
     * @return JsonResponse
     */
    public function get_modules_type(Request $request): JsonResponse
    {
        $module = Module::find($request->id);
        $packages=null;


        if ($module) {
            $packages= SubscriptionPackage::where('status',1)->where('module_type',$module?->module_type == 'rental' && addon_published_status('Rental') ? 'rental' : 'all')->latest()->get();

            $module = $module->module_type;
            return response()->json([
                'module_type' => $module,
                'view' => view('vendor-views.auth._package_data', compact('packages','module'))->render(),
            ]);
        }

        return response()->json(['module_type' => '','module_zone' => false]);
    }


    public function check_module_type(Request $request): JsonResponse
    {
        $module = Module::find($request->id);
        $moduleZone= null;
        if ($module) {
            if($request->zone_id){
            $moduleZone=  ModuleZone::where('module_id', $module->id)->where('zone_id', $request->zone_id)->exists();
            }

        }
        return response()->json(['module_zone' => $moduleZone]);
    }


    public function business_plan(Request $request){
        $store=Store::find($request->store_id);

        if ($request->business_plan == 'subscription-base' && $request->package_id != null ) {
            $key=['subscription_free_trial_days','subscription_free_trial_type','subscription_free_trial_status'];
            $free_trial_settings=BusinessSetting::whereIn('key', $key)->pluck('value','key');

            return view('vendor-views.auth.register-subscription-payment',[
            'package_id'=> $request->package_id,
            'store_id' => $request->store_id,
            'free_trial_settings'=>$free_trial_settings,
            'payment_methods' => Helpers::getActivePaymentGateways(),

            ]);
        }
        elseif($request->business_plan == 'commission-base' ){
            $store->store_business_model = 'commission';
            $store->save();
            return view('vendor-views.auth.register-complete',[
                'type'=>'commission'
            ]);
        }
        else{
            $admin_commission= BusinessSetting::where('key','admin_commission')->first();
            $business_name= BusinessSetting::where('key','business_name')->first();
            $packages= SubscriptionPackage::where('status',1)->where('module_type', 'all')->get();
            Toastr::error(translate('messages.please_follow_the_steps_properly.'));
            return view('vendor-views.auth.register-step-2',[
                'admin_commission'=> $admin_commission?->value,
                'business_name'=> $business_name?->value,
                'packages'=> $packages,
                'store_id' => $request->store_id,
                'type'=>$request->type
                ]);
        }

    }

    public function secondStep(Request $request){
        $store=Store::findOrFail($request->store_id);
        if ($request->business_plan == 'subscription-base' && $store->package_id != null ) {

            $key=['subscription_free_trial_days','subscription_free_trial_type','subscription_free_trial_status'];
            $free_trial_settings=BusinessSetting::whereIn('key', $key)->pluck('value','key');

            return view('vendor-views.auth.register-subscription-payment',[
            'package_id'=> $store->package_id,
            'store_id' => $store->id,
            'free_trial_settings'=>$free_trial_settings,
            'payment_methods' => Helpers::getActivePaymentGateways(),

            ]);
        }
        elseif($request->business_plan == 'commission-base' ){
            $store->store_business_model = 'commission';
            $store->save();
            return view('vendor-views.auth.register-complete',[
                'type'=>'commission'
            ]);
        }
        else{
            $admin_commission= BusinessSetting::where('key','admin_commission')->first();
            $business_name= BusinessSetting::where('key','business_name')->first();
            $packages= SubscriptionPackage::where('status',1)->where('module_type', 'all')->get();
            return view('vendor-views.auth.register-step-2',[
                'admin_commission'=> $admin_commission?->value,
                'business_name'=> $business_name?->value,
                'packages'=> $packages,
                'store_id' => $store->id,
                'type'=>$request->type
                ]);
        }

    }

    public function payment(Request $request){
        $request->validate([
            'package_id' => 'required',
            'store_id' => 'required',
            'payment' => 'required'
        ]);

        $store= Store::Where('id',$request->store_id)->first(['id','vendor_id']);
        $package = SubscriptionPackage::withoutGlobalScope('translate')->find($request->package_id);

        if(!in_array($request->payment,['free_trial'])){
            $url= route('restaurant.final_step',['store_id' => $store->id?? null]);
            return redirect()->away(Helpers::subscriptionPayment(store_id:$store->id,package_id:$package->id,payment_gateway:$request->payment,payment_platform:'web',url:$url,type: 'new_join'));
        }
        if($request->payment == 'free_trial'){
            $plan_data=   Helpers::subscription_plan_chosen(store_id:$store->id,package_id:$package->id,payment_method:'free_trial',discount:0,reference:'free_trial',type: 'new_join');
        }
        $plan_data != false ?  Toastr::success( translate('Successfully_Subscribed.')) : Toastr::error( translate('Something_went_wrong!.'));
        return to_route('restaurant.final_step');
    }

public function back(Request $request){
    $admin_commission= BusinessSetting::where('key','admin_commission')->first();
    $business_name= BusinessSetting::where('key','business_name')->first();
    $store=Store::where('id',$request->store_id)->with('module')->first();
    $module=$store?->module?->module_type ?? 'all';
    $packages= SubscriptionPackage::where('status',1)->where('module_type',  $module == 'rental' ? 'rental' : 'all')->get();
    return view('vendor-views.auth.register-step-2',[
        'admin_commission'=> $admin_commission?->value,
        'business_name'=> $business_name?->value,
        'packages'=> $packages,
        'store_id' => $request->store_id,
        'module' => $module
        ]);
}

    // Fox GO - tela de verificação Stripe Connect embutida no cadastro do lojista
    public function foxgoConnectOnboarding(Request $request)
    {
        $store = Store::where('id', $request->store_id)->with('vendor')->firstOrFail();
        $business_plan = $request->business_plan ?: 'commission-base';

        return view('vendor-views.auth.foxgo-connect-onboarding', [
            'store_id' => $store->id,
            'business_plan' => $business_plan,
            'store' => $store,
        ]);
    }

    // Fox GO - gera Account Session Stripe Connect sem expor chave secreta
    public function foxgoConnectAccountSession(Request $request)
    {
        $request->validate([
            'store_id' => 'required',
        ]);

        $store = Store::where('id', $request->store_id)->with('vendor')->firstOrFail();

        try {
            $session = FoxGoStripeConnectOnboardingLogic::createAccountSession($store);

            return response()->json([
                'client_secret' => $session['client_secret'],
                'published_key' => $session['published_key'],
            ]);
        } catch (\Throwable $e) {
            info('FoxGoStripeConnectOnboarding: erro session store_id=' . $store->id . ' erro=' . $e->getMessage());

            return response()->json([
                'message' => 'Não foi possível iniciar a verificação de recebimento. Tente novamente.',
            ], 422);
        }
    }

    // Fox GO - atualiza status da conta Connect após onboarding
    public function foxgoConnectStatus(Request $request)
    {
        $request->validate([
            'store_id' => 'required',
        ]);

        $store = Store::where('id', $request->store_id)->with('vendor')->firstOrFail();

        try {
            $vendor = FoxGoStripeConnectOnboardingLogic::refreshAccountStatus($store);

            return response()->json([
                'status' => $vendor->stripe_connect_status,
                'charges_enabled' => (int) $vendor->stripe_charges_enabled,
                'payouts_enabled' => (int) $vendor->stripe_payouts_enabled,
                'details_submitted' => (int) $vendor->stripe_details_submitted,
                'requirements_due' => json_decode($vendor->stripe_requirements_due ?: '[]', true),
                'redirect_url' => route('restaurant.secondStep', [
                    'store_id' => $store->id,
                    'business_plan' => $request->business_plan ?: 'commission-base',
                ]),
            ]);
        } catch (\Throwable $e) {
            info('FoxGoStripeConnectOnboarding: erro status store_id=' . $store->id . ' erro=' . $e->getMessage());

            return response()->json([
                'message' => 'Não foi possível confirmar a verificação de recebimento. Tente novamente.',
            ], 422);
        }
    }
public function final_step(Request $request){


    $store_id= null;
    $payment_status= null;
    if($request?->store_id && is_string($request?->store_id)){
        $data = explode('?', $request?->store_id);
        $store_id = $data[0];
        $payment_status = $data[1]  != 'flag=success' ? 'fail': 'success';
    }

    return view('vendor-views.auth.register-complete',['store_id' =>$store_id,'payment_status'=> $payment_status]);
}

}
