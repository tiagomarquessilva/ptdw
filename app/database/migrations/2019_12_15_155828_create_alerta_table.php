<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAlertaTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('alerta', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->boolean('resolvido');
            $table->text('comentario', 255)->nullable($value = true);
            $table->integer('descricao_alerta_id');
            $table->integer('paciente_id');
            $table->integer('tipo_alerta_id');
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
        Schema::dropIfExists('alerta');
    }
}
