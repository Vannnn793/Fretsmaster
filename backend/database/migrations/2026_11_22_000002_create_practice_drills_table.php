<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('practice_drills', function (Blueprint $table) {
            $table->id();
            $table->string('title', 150);
            $table->text('description')->nullable();
            $table->json('chords');      // Array chord sequence e.g. ["Em", "C", "G", "D"]
            $table->integer('target_bpm')->default(60);
            $table->string('difficulty', 50)->default('Pemula');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('practice_drills');
    }
};
