<?php

namespace Tests\Feature;

use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CategoryMasterDataTest extends TestCase
{
    use RefreshDatabase;

    public function test_category_store_persists_expense_category(): void
    {
        $response = $this->postJson('/api/categories', [
            'name' => 'Biaya Operasional',
            'type' => 'expense',
            'is_active' => true,
        ]);

        $response
            ->assertOk()
            ->assertJsonFragment([
                'name' => 'Biaya Operasional',
                'type' => 'expense',
            ]);

        $this->assertDatabaseHas('categories', [
            'name' => 'Biaya Operasional',
            'type' => 'expense',
            'is_active' => 1,
        ]);
    }

    public function test_category_update_can_toggle_active_status(): void
    {
        $category = Category::create([
            'name' => 'Transport Harian',
            'type' => 'expense',
            'is_active' => true,
        ]);

        $response = $this->putJson("/api/categories/{$category->id}", [
            'is_active' => false,
        ]);

        $response
            ->assertOk()
            ->assertJsonFragment([
                'id' => $category->id,
                'is_active' => false,
            ]);

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
            'is_active' => 0,
        ]);
    }

    public function test_category_update_can_use_post_method_override(): void
    {
        $category = Category::create([
            'name' => 'Belanja Bulanan',
            'type' => 'expense',
            'is_active' => true,
        ]);

        $response = $this->post("/api/categories/{$category->id}", [
            '_method' => 'PUT',
            'is_active' => '0',
        ]);

        $response->assertOk();

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
            'is_active' => 0,
        ]);
    }
}
