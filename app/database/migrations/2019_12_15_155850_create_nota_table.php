<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateNotaTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('nota', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->text('nome', 255);
            $table->text('descricao', 255)->nullable($value = true);
            $table->integer('paciente_id');
            $table->integer('criado_por');
            $table->timestamp('data_registo');
            $table->boolean('ativo')->default(true);
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
        Schema::dropIfExists('nota');
    }
}
