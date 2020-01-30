<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHistoricoConfiguracoesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('historico_configuracoes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->float('emg_min')->nullable();
            $table->float('emg_max')->nullable();
            $table->integer('bpm_min')->nullable();
            $table->integer('bpm_max')->nullable();
            $table->integer('paciente_id');
            $table->integer('equipamento_id');
            $table->timestamp('data_registo');
            // esta_associado controla se equipamente está em uso
            $table->boolean('esta_associado')->default(false);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('historico_configuracoes');
    }
}
