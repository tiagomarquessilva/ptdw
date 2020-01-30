<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePacienteTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('paciente', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->text('nome', 255);
            $table->char('sexo', 1);
            $table->date('data_nascimento');
            $table->date('data_diagnostico');
            //$table->boolean('pedido_ajuda');
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
        Schema::dropIfExists('paciente');
    }
}
