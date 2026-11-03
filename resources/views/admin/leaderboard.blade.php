@extends('admin.layouts.app')
@section('title', 'Leaderboard Config')

@section('content')
  <div class="grid-2">
    <div class="card no-pad">
      <div class="card-header"><span class="card-title">Point Weights</span></div>
      <form method="POST" action="{{ route('admin.leaderboard.update') }}">@csrf @method('PUT')
        <div style="padding:16px 20px;">
          @foreach([
              'leaderboard_points_achievement' => ['Points per verified achievement', 'Awarded for each verified achievement (default 50).'],
              'leaderboard_points_completion' => ['Profile completion milestone', 'One-off bonus when a profile reaches 80% completion (default 20).'],
              'leaderboard_points_participation' => ['Points per approved participation', 'Per approved trial/tournament registration (default 10).'],
              'leaderboard_participation_cap' => ['Participation cap', 'Maximum total points from participation (default 50).'],
          ] as $key => [$label, $help])
            <div class="form-group" style="margin-bottom:18px;">
              <label style="font-weight:600;font-size:13px;display:flex;justify-content:space-between;">
                {{ $label }}
                <span style="color:#6b7280;">pts</span>
              </label>
              <input class="input" type="number" name="{{ $key }}" value="{{ $weights[$key] }}" min="0" max="1000" required>
              <div style="font-size:11px;color:#6b7280;margin-top:4px;">{{ $help }}</div>
            </div>
          @endforeach
          <button class="btn btn-primary"><i data-lucide="check" style="width:14px;height:14px;"></i> Save Weights</button>
        </div>
      </form>
    </div>

    <div>
      <div class="card no-pad" style="margin-bottom:20px;">
        <div class="card-header"><span class="card-title">Active Season</span></div>
        <div style="padding:16px 20px;font-size:13px;color:#374151;">
          <div style="font-size:16px;font-weight:700;color:#111827;">{{ $season->name }}</div>
          <div style="margin-top:4px;">Started {{ $season->starts_on }} · Season #{{ $season->id }}</div>
          <div style="margin-top:10px;color:#6b7280;font-size:12px;">
            Scores are recalculated per athlete × sport into the active season. Weights saved here apply from the next recalculation (event-driven or the nightly job at 04:00).
          </div>
        </div>
      </div>

      <div class="card no-pad">
        <div class="card-header"><span class="card-title">Recalculate</span></div>
        <div style="padding:16px 20px;">
          <p style="font-size:13px;color:#374151;margin:0 0 12px;">
            Rebuild every athlete's score from the current weights and data now, instead of waiting for the scheduled job.
          </p>
          <form method="POST" action="{{ route('admin.leaderboard.reset') }}" onsubmit="return confirm('Recalculate the entire leaderboard now? This may take a moment on large datasets.')">
            @csrf
            <button class="btn btn-primary"><i data-lucide="rotate-ccw" style="width:14px;height:14px;"></i> Reset Leaderboard Now</button>
          </form>
        </div>
      </div>
    </div>
  </div>
@endsection
