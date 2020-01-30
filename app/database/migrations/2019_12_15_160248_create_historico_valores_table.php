<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHistoricoValoresTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('historico_valores', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->float('emg');
            $table->integer('bc');
            $table->integer('paciente_id');
            $table->integer('equipamento_id');
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
        Schema::dropIfExists('historico_valores');
    }
}
