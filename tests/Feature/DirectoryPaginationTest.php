<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

/**
 * Pagination contract regression test.
 *  - B3: directories return a flat Laravel paginator (top-level current_page /
 *    last_page / data) with NO `meta` wrapper.
 */
class DirectoryPaginationTest extends TestCase
{
    use RefreshDatabase;

    public function test_trials_returns_flat_paginator_without_meta_wrapper(): void
    {
        $resp = $this->getJson('/api/v1/trials?page=1&per_page=10');

        $resp->assertStatus(200)
            ->assertJsonStructure(['current_page', 'data', 'last_page', 'per_page', 'total'])
            ->assertJsonMissingPath('meta');
    }
}
