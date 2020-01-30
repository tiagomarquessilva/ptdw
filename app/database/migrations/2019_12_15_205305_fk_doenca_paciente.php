<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class FkDoencaPaciente extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('doenca_paciente', function (Blueprint $table) {
            $table->foreign('paciente_id')->references('id')->on('paciente');
            $table->foreign('doenca_id')->references('id')->on('doenca');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('doenca_paciente', function (Blueprint $table) {
            //
        });
    }
}
