<?php

namespace App\Http\Controllers\Vendor;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\FoxGoStoreCatalogBrand;
use App\Models\FoxGoStoreCatalogCategory;
use App\Models\FoxGoStoreItemCatalogProfile;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class FoxGoStoreCatalogController extends Controller
{
    private function storeId(): int
    {
        return (int) Helpers::get_store_id();
    }

    private function moduleId()
    {
        $store = Helpers::get_store_data();
        return $store && $store->module_id ? (int) $store->module_id : null;
    }

    private function canUseCatalog(): bool
    {
        $store = Helpers::get_store_data();

        if (!$store || !$store->item_section) {
            Toastr::warning(translate('messages.permission_denied'));
            return false;
        }

        return true;
    }

    public function index()
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $storeId = $this->storeId();

        $categories = FoxGoStoreCatalogCategory::where('store_id', $storeId)->where('parent_id', 0)->orderBy('name')->get();
        $subcategories = FoxGoStoreCatalogCategory::where('store_id', $storeId)->where('parent_id', '>', 0)->orderBy('name')->get();
        $brands = FoxGoStoreCatalogBrand::where('store_id', $storeId)->orderBy('name')->get();
        $parentNames = FoxGoStoreCatalogCategory::where('store_id', $storeId)->where('parent_id', 0)->pluck('name', 'id');

        return view('vendor-views.foxgo-catalog.index', compact('categories', 'subcategories', 'brands', 'parentNames'));
    }

    public function storeCategory(Request $request)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $request->validate([
            'name' => 'required|string|max:191',
            'parent_id' => 'nullable|integer|min:0',
        ]);

        $storeId = $this->storeId();
        $parentId = (int) ($request->parent_id ?? 0);

        if ($parentId > 0 && !$this->validParent($storeId, $parentId)) {
            Toastr::error('Categoria principal inválida para esta loja.');
            return back();
        }

        $name = trim((string) $request->name);

        FoxGoStoreCatalogCategory::create([
            'store_id' => $storeId,
            'module_id' => $this->moduleId(),
            'parent_id' => $parentId,
            'name' => $name,
            'slug' => $this->uniqueCategorySlug($storeId, $parentId, $name),
            'position' => $parentId > 0 ? 1 : 0,
            'sort_order' => 0,
            'status' => true,
            'is_enabled' => true,
        ]);

        Toastr::success($parentId > 0 ? 'Subcategoria criada com sucesso.' : 'Categoria criada com sucesso.');
        return back();
    }

    public function updateCategory(Request $request, $id)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $category = FoxGoStoreCatalogCategory::where('store_id', $this->storeId())->findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:191',
            'parent_id' => 'nullable|integer|min:0',
        ]);

        $storeId = $this->storeId();
        $parentId = (int) ($request->parent_id ?? 0);

        if ($parentId === (int) $category->id) {
            Toastr::error('Uma categoria não pode ser subcategoria dela mesma.');
            return back();
        }

        if ($parentId > 0 && !$this->validParent($storeId, $parentId)) {
            Toastr::error('Categoria principal inválida para esta loja.');
            return back();
        }

        $name = trim((string) $request->name);

        $category->name = $name;
        $category->parent_id = $parentId;
        $category->position = $parentId > 0 ? 1 : 0;
        $category->slug = $this->uniqueCategorySlug($storeId, $parentId, $name, (int) $category->id);
        $category->save();

        Toastr::success('Categoria atualizada com sucesso.');
        return back();
    }

    public function statusCategory($id, $status)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $category = FoxGoStoreCatalogCategory::where('store_id', $this->storeId())->findOrFail($id);
        $category->status = (bool) $status;
        $category->is_enabled = (bool) $status;
        $category->save();

        Toastr::success('Status atualizado com sucesso.');
        return back();
    }

    public function deleteCategory($id)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $storeId = $this->storeId();
        $category = FoxGoStoreCatalogCategory::where('store_id', $storeId)->findOrFail($id);

        if (FoxGoStoreCatalogCategory::where('store_id', $storeId)->where('parent_id', $category->id)->exists()) {
            Toastr::warning('Não é possível excluir uma categoria que possui subcategorias.');
            return back();
        }

        $isUsed = FoxGoStoreItemCatalogProfile::where('store_id', $storeId)
            ->where(function ($query) use ($category) {
                $query->where('store_catalog_category_id', $category->id)
                    ->orWhere('store_catalog_sub_category_id', $category->id);
            })
            ->exists();

        if ($isUsed) {
            Toastr::warning('Não é possível excluir: essa categoria está vinculada a itens da loja.');
            return back();
        }

        $category->delete();

        Toastr::success('Categoria excluída com sucesso.');
        return back();
    }

    public function storeBrand(Request $request)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $request->validate([
            'name' => 'required|string|max:191',
        ]);

        $storeId = $this->storeId();
        $name = trim((string) $request->name);

        FoxGoStoreCatalogBrand::create([
            'store_id' => $storeId,
            'module_id' => $this->moduleId(),
            'name' => $name,
            'slug' => $this->uniqueBrandSlug($storeId, $name),
            'status' => true,
            'is_enabled' => true,
        ]);

        Toastr::success('Marca/linha criada com sucesso.');
        return back();
    }

    public function updateBrand(Request $request, $id)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $brand = FoxGoStoreCatalogBrand::where('store_id', $this->storeId())->findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:191',
        ]);

        $name = trim((string) $request->name);
        $brand->name = $name;
        $brand->slug = $this->uniqueBrandSlug($this->storeId(), $name, (int) $brand->id);
        $brand->save();

        Toastr::success('Marca/linha atualizada com sucesso.');
        return back();
    }

    public function statusBrand($id, $status)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $brand = FoxGoStoreCatalogBrand::where('store_id', $this->storeId())->findOrFail($id);
        $brand->status = (bool) $status;
        $brand->is_enabled = (bool) $status;
        $brand->save();

        Toastr::success('Status atualizado com sucesso.');
        return back();
    }

    public function deleteBrand($id)
    {
        if (!$this->canUseCatalog()) {
            return back();
        }

        $storeId = $this->storeId();
        $brand = FoxGoStoreCatalogBrand::where('store_id', $storeId)->findOrFail($id);

        if (FoxGoStoreItemCatalogProfile::where('store_id', $storeId)->where('store_catalog_brand_id', $brand->id)->exists()) {
            Toastr::warning('Não é possível excluir: essa marca/linha está vinculada a itens da loja.');
            return back();
        }

        $brand->delete();

        Toastr::success('Marca/linha excluída com sucesso.');
        return back();
    }

    private function validParent(int $storeId, int $parentId): bool
    {
        return FoxGoStoreCatalogCategory::where('store_id', $storeId)
            ->where('id', $parentId)
            ->where('parent_id', 0)
            ->exists();
    }

    private function uniqueCategorySlug(int $storeId, int $parentId, string $name, ?int $ignoreId = null): string
    {
        $base = Str::slug($name) ?: 'categoria';
        $slug = $base;
        $counter = 2;

        while (true) {
            $query = FoxGoStoreCatalogCategory::where('store_id', $storeId)->where('parent_id', $parentId)->where('slug', $slug);

            if ($ignoreId) {
                $query->where('id', '!=', $ignoreId);
            }

            if (!$query->exists()) {
                return $slug;
            }

            $slug = "{$base}-{$counter}";
            $counter++;
        }
    }

    private function uniqueBrandSlug(int $storeId, string $name, ?int $ignoreId = null): string
    {
        $base = Str::slug($name) ?: 'marca';
        $slug = $base;
        $counter = 2;

        while (true) {
            $query = FoxGoStoreCatalogBrand::where('store_id', $storeId)->where('slug', $slug);

            if ($ignoreId) {
                $query->where('id', '!=', $ignoreId);
            }

            if (!$query->exists()) {
                return $slug;
            }

            $slug = "{$base}-{$counter}";
            $counter++;
        }
    }
}
