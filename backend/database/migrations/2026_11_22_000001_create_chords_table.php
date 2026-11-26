<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chords', function (Blueprint $table) {
            $table->id();
            $table->string('name', 20)->unique();
            $table->string('full_name', 100);
            $table->string('notes', 100);
            $table->json('frets');     // Array 6 integer [-1..5] dari senar 6 ke 1
            $table->json('fingers');   // Array 6 integer [0..4] nomor jari
            $table->string('difficulty', 50)->default('Mudah');
            $table->text('tip')->nullable();
            $table->string('strum', 150)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chords');
    }
};
