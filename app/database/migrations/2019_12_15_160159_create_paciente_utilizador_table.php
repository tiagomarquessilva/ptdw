<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePacienteUtilizadorTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('paciente_utilizador', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->integer('paciente_id');
            $table->integer('utilizador_id');
            $table->integer('relacao_paciente_id')->nullable($value = true);
            $table->timestamp('data_registo');
            $table->timestamp('data_update')->nullable($value = true);
            $table->boolean('ativo');
            $table->integer('log_utilizador_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('paciente_utilizador');
    }
}
