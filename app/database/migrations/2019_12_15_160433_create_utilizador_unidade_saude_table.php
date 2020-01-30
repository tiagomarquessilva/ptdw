<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUtilizadorUnidadeSaudeTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('utilizador_unidade_saude', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->integer('utilizador_id');
            $table->integer('unidade_saude_id');
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
        Schema::dropIfExists('utilizador_unidade_saude');
    }
}
