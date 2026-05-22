<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('foxgo_store_catalog_categories')) {
            Schema::create('foxgo_store_catalog_categories', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('store_id');
                $table->unsignedBigInteger('module_id')->nullable();
                $table->unsignedBigInteger('parent_id')->default(0);
                $table->string('name');
                $table->string('slug');
                $table->integer('position')->default(0); // 0 categoria, 1 subcategoria
                $table->integer('sort_order')->default(0);
                $table->boolean('status')->default(true);
                $table->boolean('is_enabled')->default(true);
                $table->timestamps();

                $table->index('store_id', 'fg_cat_store_idx');
                $table->index('module_id', 'fg_cat_module_idx');
                $table->index('parent_id', 'fg_cat_parent_idx');
                $table->index(['store_id', 'parent_id'], 'fg_cat_store_parent_idx');
                $table->unique(['store_id', 'parent_id', 'slug'], 'fg_cat_store_parent_slug_uid');
            });
        }

        if (!Schema::hasTable('foxgo_store_catalog_brands')) {
            Schema::create('foxgo_store_catalog_brands', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('store_id');
                $table->unsignedBigInteger('module_id')->nullable();
                $table->string('name');
                $table->string('slug');
                $table->boolean('status')->default(true);
                $table->boolean('is_enabled')->default(true);
                $table->timestamps();

                $table->index('store_id', 'fg_brand_store_idx');
                $table->index('module_id', 'fg_brand_module_idx');
                $table->unique(['store_id', 'slug'], 'fg_brand_store_slug_uid');
            });
        }

        if (!Schema::hasTable('foxgo_store_item_catalog_profiles')) {
            Schema::create('foxgo_store_item_catalog_profiles', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('store_id');
                $table->unsignedBigInteger('item_id');
                $table->unsignedBigInteger('store_catalog_category_id')->nullable();
                $table->unsignedBigInteger('store_catalog_sub_category_id')->nullable();
                $table->unsignedBigInteger('store_catalog_brand_id')->nullable();
                $table->boolean('is_enabled')->default(true);
                $table->timestamps();

                $table->index('store_id', 'fg_itemcat_store_idx');
                $table->unique('item_id', 'fg_itemcat_item_uid');
                $table->index('store_catalog_category_id', 'fg_itemcat_cat_idx');
                $table->index('store_catalog_sub_category_id', 'fg_itemcat_subcat_idx');
                $table->index('store_catalog_brand_id', 'fg_itemcat_brand_idx');
                $table->index(['store_id', 'store_catalog_category_id'], 'fg_itemcat_store_cat_idx');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_store_item_catalog_profiles');
        Schema::dropIfExists('foxgo_store_catalog_brands');
        Schema::dropIfExists('foxgo_store_catalog_categories');
    }
};
