<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUtilizadorTipoTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('utilizador_tipo', function (Blueprint $table) {
	    $table->bigIncrements('id');
            $table->integer('utilizador_id');
            $table->integer('tipo_id');
	    $table->timestamp('data_registo')->nullable();
	    $table->timestamp('data_update')->nullable();
            $table->boolean('ativo')->default(true);
	    $table->integer('log_utilizador_id')->nullable();

            $table->foreign('utilizador_id')->references('id')->on('utilizador');
            $table->foreign('tipo_id')->references('id')->on('tipos');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('utilizador__tipo');
    }
}
