<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePedidoAjudaTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('pedido_ajuda', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->text('nome', 255);
            $table->text('descricao', 255)->nullable($value = true);
            $table->boolean('resolvido');
            $table->integer('paciente_id');
            $table->integer('utilizador_id');
            $table->timestamp('data_registo');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('pedido_ajuda');
    }
}
