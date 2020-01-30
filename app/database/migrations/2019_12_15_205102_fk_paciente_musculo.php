<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class FkPacienteMusculo extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('paciente_musculo', function (Blueprint $table) {
            $table->foreign('paciente_id')->references('id')->on('paciente');
            $table->foreign('musculo_id')->references('id')->on('musculo');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('paciente_musculo', function (Blueprint $table) {
            //
        });
    }
}
