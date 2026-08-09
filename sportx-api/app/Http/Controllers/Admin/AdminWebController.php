<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AdminWebController extends Controller
{
    public function login()
    {
        return view('admin.login');
    }

    public function dashboard()
    {
        return view('admin.dashboard');
    }

    public function users()
    {
        return view('admin.users');
    }

    public function userDetail($id)
    {
        return view('admin.user-detail', ['userId' => $id]);
    }

    public function approvals()
    {
        return view('admin.approvals');
    }

    public function moderation()
    {
        return view('admin.moderation');
    }

    public function reportDetail($id)
    {
        return view('admin.report-detail', ['reportId' => $id]);
    }

    public function composeNotification()
    {
        return view('admin.notification-compose');
    }

    public function opportunities()
    {
        return view('admin.opportunities');
    }

    public function reports()
    {
        return view('admin.reports');
    }

    public function analytics()
    {
        return view('admin.analytics');
    }

    public function sponsors()
    {
        return view('admin.sponsor-verification');
    }

    public function categories()
    {
        return view('admin.categories');
    }

    public function settings()
    {
        return view('admin.system-settings');
    }
}
