<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('practice_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('drill_id')->nullable()->constrained('practice_drills')->nullOnDelete();
            $table->string('chord_name', 20)->nullable();
            $table->float('accuracy')->default(0.0);
            $table->integer('bpm')->default(60);
            $table->integer('duration_seconds')->default(0);
            $table->string('notes', 255)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('practice_logs');
    }
};
