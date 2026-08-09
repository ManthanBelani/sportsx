<?php

namespace App\Services;

use DateTime;
use DateTimeZone;

class IcsService
{
    /**
     * Generate an ICS file content for an event.
     */
    public function generateEventIcs(string $title, string $description, DateTime $start, DateTime $end, string $location, string $uid): string
    {
        $dtStart = $start->setTimezone(new DateTimeZone('UTC'))->format('Ymd\THis\Z');
        $dtEnd = $end->setTimezone(new DateTimeZone('UTC'))->format('Ymd\THis\Z');
        $dtStamp = now()->setTimezone(new DateTimeZone('UTC'))->format('Ymd\THis\Z');

        // Escape commas, semicolons, and newlines in text fields
        $title = $this->escapeString($title);
        $description = $this->escapeString($description);
        $location = $this->escapeString($location);

        return "BEGIN:VCALENDAR\r\n" .
            "VERSION:2.0\r\n" .
            "PRODID:-//SportX//Event Calendar//EN\r\n" .
            "CALSCALE:GREGORIAN\r\n" .
            "BEGIN:VEVENT\r\n" .
            "UID:{$uid}\r\n" .
            "DTSTAMP:{$dtStamp}\r\n" .
            "DTSTART:{$dtStart}\r\n" .
            "DTEND:{$dtEnd}\r\n" .
            "SUMMARY:{$title}\r\n" .
            "DESCRIPTION:{$description}\r\n" .
            "LOCATION:{$location}\r\n" .
            "END:VEVENT\r\n" .
            "END:VCALENDAR";
    }

    private function escapeString(string $string): string
    {
        return str_replace(['\\', ',', ';', "\n"], ['\\\\', '\,', '\;', '\n'], $string);
    }
}
