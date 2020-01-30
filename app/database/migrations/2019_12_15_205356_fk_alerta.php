<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class FkAlerta extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('alerta', function (Blueprint $table) {
            $table->foreign('descricao_alerta_id')->references('id')->on('descricao_alerta');
            $table->foreign('paciente_id')->references('id')->on('paciente');
            $table->foreign('tipo_alerta_id')->references('id')->on('tipo_alerta');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('alerta', function (Blueprint $table) {
            //
        });
    }
}
