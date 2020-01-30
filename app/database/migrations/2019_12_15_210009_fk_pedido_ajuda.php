<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class FkPedidoAjuda extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('pedido_ajuda', function (Blueprint $table) {
            $table->foreign('paciente_id')->references('id')->on('paciente');
            $table->foreign('utilizador_id')->references('id')->on('utilizador');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('pedido_ajuda', function (Blueprint $table) {
            //
        });
    }
}
