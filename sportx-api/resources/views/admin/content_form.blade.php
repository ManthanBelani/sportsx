@extends('admin.layouts.app')
@section('title', ($item ? 'Edit' : 'New') . ' ' . ucfirst(str_replace('-',' ', $type)))
@section('header-actions')
  <a href="{{ route('admin.content.list', $type) }}" class="btn btn-ghost">← Back</a>
@endsection

@section('content')
<div class="card" style="max-width:760px;">
  <div class="card-header"><span class="card-title">{{ $item ? 'Edit' : 'Create' }} {{ ucfirst(str_replace('-',' ', $type)) }}</span></div>
  <form method="POST" action="{{ $item ? route('admin.content.update', [$type, $item->id]) : route('admin.content.store', $type) }}">
    @csrf
    @if($item) @method('PUT') @endif

    @if(!empty($ownerConfig))
      <div class="form-group" style="grid-column:1/-1; margin-bottom:16px; padding:12px; background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px;">
        <label class="form-label">{{ $ownerConfig['label'] }} — on behalf of</label>
        <select class="select" name="owner_user_id">
          <option value="">— Admin (self) / keep existing —</option>
          @foreach($ownerOptions as $u)
            <option value="{{ $u->id }}" @if((string)($currentOwnerUserId ?? '')===(string)$u->id) selected @endif>{{ $u->name }} — {{ $u->email }} ({{ $u->role }})</option>
          @endforeach
        </select>
        <div style="font-size:12px; color:#64748b; margin-top:6px;">Select who this {{ rtrim($type,'s') }} belongs to. Leave as “Admin” to create as yourself (admin-owned) or keep current owner when editing.</div>
      </div>
    @endif

    <div class="grid-2">
      @foreach($fields as $f)
        @php
          $raw = $item?->{$f};
          // Some casts return ArrayObject / Collection or nested arrays
          if ($raw instanceof \Illuminate\Database\Eloquent\Casts\AsArrayObject) $raw = $raw->toArray();
          if ($raw instanceof \Illuminate\Support\Collection) $raw = $raw->toArray();
          $isArray = in_array($f, $arrayFields);
          if (is_array($raw)) {
            $val = implode("\n", array_map(fn($v) => is_array($v) || is_object($v) ? json_encode($v, JSON_UNESCAPED_UNICODE) : (string)$v, $raw));
          } else {
            $val = $raw;
          }
          $isSelect = in_array($f, ['sport_id','city_id','age_group_id','status','listing_status']);
          $isBool = in_array($f, ['booking_available','personal_coaching','is_active']);
          $isLong = $isArray || in_array($f, ['description','bio','benefits','eligibility','eligibility_criteria','benefits_offered','rules','address','facilities','achievements','fee_structure','certifications','languages','pricing','working_hours','required_documents','documents_required']);
          $isDate = str_ends_with($f, '_at') || in_array($f, ['deadline','event_datetime','start_date','end_date','expires_at','registration_deadline']);
          $isNum = in_array($f, ['vacancies','amount','entry_fee','prize_pool','experience','year_established','sort_order','min_age','max_age']);
          $isEmail = str_contains($f,'email');
          $isUrl = str_contains($f,'url') || str_contains($f,'link') || in_array($f,['website','google_maps_url','registration_link','application_link']);
          $label = ucfirst(str_replace('_',' ',$f));
        @endphp

        <div class="form-group" style="{{ ($isLong || $isArray) ? 'grid-column:1/-1;' : '' }}">
          <label class="form-label">{{ $label }}{{ $isArray ? ' (one per line)' : '' }}</label>

          @if($f === 'sport_id')
            <select class="select" name="{{ $f }}">
              <option value="">—</option>
              @foreach($sports as $s)<option value="{{ $s->id }}" @if((string)$val===(string)$s->id) selected @endif>{{ $s->name }}</option>@endforeach
            </select>
          @elseif($f === 'city_id')
            <select class="select" name="{{ $f }}">
              <option value="">—</option>
              @foreach($cities as $c)<option value="{{ $c->id }}" @if((string)$val===(string)$c->id) selected @endif>{{ $c->name }}</option>@endforeach
            </select>
          @elseif($f === 'age_group_id')
            <select class="select" name="{{ $f }}">
              <option value="">—</option>
              @foreach($ageGroups as $a)<option value="{{ $a->id }}" @if((string)$val===(string)$a->id) selected @endif>{{ $a->name }}</option>@endforeach
            </select>
          @elseif(in_array($f,['status','listing_status']))
            <select class="select" name="{{ $f }}">
              @foreach(['published','draft','closed'] as $st)<option value="{{ $st }}" @if($val===$st) selected @endif>{{ ucfirst($st) }}</option>@endforeach
            </select>
          @elseif($isBool)
            <label style="display:flex;align-items:center;gap:8px;font-size:14px;">
              <input type="checkbox" name="{{ $f }}" value="1" {{ $val ? 'checked' : '' }}> Enabled
            </label>
          @elseif($isLong || $isArray)
            <textarea class="input" name="{{ $f }}" rows="{{ $isArray ? 4 : 3 }}">{{ old($f, $val) }}</textarea>
          @elseif($isDate)
            @php
              $dateVal = old($f, $val);
              if ($dateVal instanceof \Carbon\CarbonInterface) $dateVal = $dateVal->format('Y-m-d\TH:i');
              elseif (is_string($dateVal) && strtotime($dateVal)) $dateVal = date('Y-m-d\TH:i', strtotime($dateVal));
              else $dateVal = $dateVal;
            @endphp
            <input class="input" type="datetime-local" name="{{ $f }}" value="{{ $dateVal }}">
          @elseif($isNum)
            <input class="input" type="number" step="any" name="{{ $f }}" value="{{ old($f, is_scalar($val) ? $val : '') }}">
          @elseif($isEmail)
            <input class="input" type="email" name="{{ $f }}" value="{{ old($f, is_scalar($val) ? $val : '') }}">
          @elseif($isUrl)
            <input class="input" type="url" name="{{ $f }}" value="{{ old($f, is_scalar($val) ? $val : '') }}">
          @else
            <input class="input" type="text" name="{{ $f }}" value="{{ old($f, is_scalar($val) ? $val : '') }}">
          @endif
        </div>
      @endforeach
    </div>

    <div style="display:flex;gap:10px;margin-top:8px;">
      <button class="btn btn-primary" type="submit"><i data-lucide="save" style="width:14px;height:14px;"></i> {{ $item ? 'Save changes' : 'Create' }}</button>
      <a href="{{ route('admin.content.list', $type) }}" class="btn btn-ghost">Cancel</a>
    </div>
  </form>
</div>
@endsection
