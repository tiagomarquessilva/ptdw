<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUnidadeSaudeTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('unidade_saude', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->text('nome', 255);
            $table->text('morada', 255);
            $table->integer('telefone');
            $table->text('email', 255);
            $table->timestamp('data_registo')->default('now()');
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
        Schema::dropIfExists('unidade_saude');
    }
}
