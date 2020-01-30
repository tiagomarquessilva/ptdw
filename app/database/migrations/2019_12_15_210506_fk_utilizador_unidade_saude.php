<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class FkUtilizadorUnidadeSaude extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('utilizador_unidade_saude', function (Blueprint $table) {
            $table->foreign('utilizador_id')->references('id')->on('utilizador');
            $table->foreign('unidade_saude_id')->references('id')->on('unidade_saude');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('utilizador_unidade_saude', function (Blueprint $table) {
            //
        });
    }
}
