<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUtilizadorTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('utilizador', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('nome');
            $table->string('password');
 	        $table->integer('contacto')->nullable();
            $table->string('email',255)->unique();
            $table->timestamp('email_verified_at')->nullable();
	        $table->integer('funcao_id')->nullable();
            $table->timestamp('data_registo')->nullable();
            $table->timestamp('data_update')->nullable();
            $table->rememberToken()->nullable();
	        $table->boolean('ativo')->deafult(true);
            $table->integer('log_utilizador_id')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('utilizador');
    }
}
