<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class FkPacienteUtilizador extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('paciente_utilizador', function (Blueprint $table) {
            $table->foreign('paciente_id')->references('id')->on('paciente');
            $table->foreign('utilizador_id')->references('id')->on('utilizador');
            $table->foreign('relacao_paciente_id')->references('id')->on('relacao_paciente');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('paciente_utilizador', function (Blueprint $table) {
            //
        });
    }
}
