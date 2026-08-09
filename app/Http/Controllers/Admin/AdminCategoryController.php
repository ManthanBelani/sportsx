<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\Sport;
use App\Models\City;
use App\Models\AgeGroup;
use Illuminate\Support\Facades\Validator;

class AdminCategoryController extends Controller
{
    // Sports
    public function sportsIndex(): JsonResponse
    {
        $sports = Sport::orderBy('name')->get();

        return response()->json([
            'data' => $sports
        ]);
    }

    public function sportsStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:sports,name',
            'is_active' => 'boolean',
        ]);

        $sport = Sport::create($validated);

        return response()->json([
            'data' => $sport
        ], 201);
    }

    public function sportsUpdate(Request $request, int $id): JsonResponse
    {
        $sport = Sport::find($id);

        if (!$sport) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Sport not found.',
                ]
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:sports,name,' . $id,
            'is_active' => 'boolean',
        ]);

        $sport->update($validated);

        return response()->json([
            'data' => $sport
        ]);
    }

    public function sportsDestroy(int $id): JsonResponse
    {
        $sport = Sport::find($id);

        if (!$sport) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Sport not found.',
                ]
            ], 404);
        }

        // Soft delete - mark as inactive
        $sport->update(['is_active' => false]);

        return response()->json(null, 204);
    }

    // Cities
    public function citiesIndex(): JsonResponse
    {
        $cities = City::with('state')->orderBy('name')->get();

        return response()->json([
            'data' => $cities
        ]);
    }

    public function citiesStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:cities,name',
            'state' => 'required|string|max:100',
            'is_active' => 'boolean',
        ]);

        $city = City::create($validated);

        return response()->json([
            'data' => $city
        ], 201);
    }

    public function citiesUpdate(Request $request, int $id): JsonResponse
    {
        $city = City::find($id);

        if (!$city) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'City not found.',
                ]
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:cities,name,' . $id,
            'state' => 'required|string|max:100',
            'is_active' => 'boolean',
        ]);

        $city->update($validated);

        return response()->json([
            'data' => $city
        ]);
    }

    public function citiesDestroy(int $id): JsonResponse
    {
        $city = City::find($id);

        if (!$city) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'City not found.',
                ]
            ], 404);
        }

        // Soft delete - mark as inactive
        $city->update(['is_active' => false]);

        return response()->json(null, 204);
    }

    // Age Groups
    public function ageGroupsIndex(): JsonResponse
    {
        $ageGroups = AgeGroup::orderBy('min_age')->get();

        return response()->json([
            'data' => $ageGroups
        ]);
    }

    public function ageGroupsStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:50|unique:age_groups,name',
            'min_age' => 'required|integer|min:1',
            'max_age' => 'required|integer|gte:min_age',
            'is_active' => 'boolean',
        ]);

        $ageGroup = AgeGroup::create($validated);

        return response()->json([
            'data' => $ageGroup
        ], 201);
    }

    public function ageGroupsUpdate(Request $request, int $id): JsonResponse
    {
        $ageGroup = AgeGroup::find($id);

        if (!$ageGroup) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Age group not found.',
                ]
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:50|unique:age_groups,name,' . $id,
            'min_age' => 'required|integer|min:1',
            'max_age' => 'required|integer|gte:min_age',
            'is_active' => 'boolean',
        ]);

        $ageGroup->update($validated);

        return response()->json([
            'data' => $ageGroup
        ]);
    }

    public function ageGroupsDestroy(int $id): JsonResponse
    {
        $ageGroup = AgeGroup::find($id);

        if (!$ageGroup) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Age group not found.',
                ]
            ], 404);
        }

        // Soft delete - mark as inactive
        $ageGroup->update(['is_active' => false]);

        return response()->json(null, 204);
    }
}
