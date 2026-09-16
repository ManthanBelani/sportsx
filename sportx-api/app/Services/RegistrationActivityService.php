<?php

namespace App\Services;

use App\Models\RegistrationActivityLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class RegistrationActivityService
{
    public function log(
        string $registrationType,
        int $registrationId,
        string $action,
        User $actor,
        array $metadata = []
    ): RegistrationActivityLog {
        return RegistrationActivityLog::create([
            'registration_type' => $registrationType,
            'registration_id' => $registrationId,
            'action' => $action,
            'actor_type' => $actor->role,
            'actor_id' => $actor->id,
            'metadata' => $metadata,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);
    }

    public function logSubmission(Model $registration, User $athlete): RegistrationActivityLog
    {
        return $this->log(
            $this->registrationType($registration),
            $registration->getKey(),
            'submitted',
            $athlete,
            ['submitted_at' => now()->toIso8601String()]
        );
    }

    public function logApproval(Model $registration, User $approver): RegistrationActivityLog
    {
        return $this->log(
            $this->registrationType($registration),
            $registration->getKey(),
            'approved',
            $approver,
            ['approved_at' => now()->toIso8601String()]
        );
    }

    public function logRejection(Model $registration, User $rejector, string $reason): RegistrationActivityLog
    {
        return $this->log(
            $this->registrationType($registration),
            $registration->getKey(),
            'rejected',
            $rejector,
            [
                'rejection_reason' => $reason,
                'rejected_at' => now()->toIso8601String(),
            ]
        );
    }

    private function registrationType(Model $registration): string
    {
        return match (true) {
            $registration instanceof \App\Models\TournamentRegistration => 'tournament',
            $registration instanceof \App\Models\TrialRegistration => 'trial',
            $registration instanceof \App\Models\CoachingEnrollment => 'coaching',
            default => class_basename($registration),
        };
    }
}
