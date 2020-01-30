<?php

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        // $this->call(UsersTableSeeder::class);


        /**
         * inserir utilizadores
         */
        $user1 = DB::table('utilizador')->insertGetId(['nome' => "admin",'email' =>'admin@admin.com','password' => bcrypt('admin'),"ativo" => true]);
        $user2 = DB::table('utilizador')->insertGetId(['nome' => "psaude",'email' =>'psaude@psaude.com','password' => bcrypt('psaude'),"ativo" => true]);
        $user3 = DB::table('utilizador')->insertGetId(['nome' => "cuidador",'email' =>'cuidador@cuidador.com','password' => bcrypt('cuidador'),"ativo" => true]);

        /**
         * inserir tipos de contas
         */
        $tipo1 = DB::table('tipos')->insertGetId(['nome' => "admin"]);
        $tipo2 = DB::table('tipos')->insertGetId(['nome' => "profissional de saude"]);
        $tipo3 = DB::table('tipos')->insertGetId(['nome' => "cuidador"]);


        /**
         * associar tipos de contas aos utilizadores
         */
        DB::table('utilizador_tipo')->insert(['utilizador_id' => $user1,'tipo_id' =>$tipo1, "ativo" => true]);
        //DB::table('utilizador_tipo')->insert(['utilizador_id' => $user1,'tipo_id' =>$tipo2, "ativo" => true]);
        //DB::table('utilizador_tipo')->insert(['utilizador_id' => $user1,'tipo_id' =>$tipo3, "ativo" => true]);

        DB::table('utilizador_tipo')->insert(['utilizador_id' => $user2,'tipo_id' =>$tipo2, "ativo" => true]);
        DB::table('utilizador_tipo')->insert(['utilizador_id' => $user3,'tipo_id' =>$tipo3, "ativo" => true]);


        /**
         * Inserir doenças
         */
        DB::table('doenca')->insert(['nome' => "ELA"]);
        DB::table('doenca')->insert(['nome' => "Paralisia Cerebral"]);

        /**
         * Inserir Musculos
         */
        DB::table('musculo')->insert(['nome' => "Bochecha Direita"]);
        DB::table('musculo')->insert(['nome' => "Bochecha Esquerda"]);


        /**
         * Inserir descricao_alerta
         */
        DB::table('descricao_alerta')->insert(['mensagem' => "Chamou"]);
        DB::table('descricao_alerta')->insert(['mensagem' => "Chamou de URGÊNCIA"]);


        /**
         * Inserir tipo_alerta
         */
        DB::table('tipo_alerta')->insert(['nome' => "Chamada"]);
        DB::table('tipo_alerta')->insert(['nome' => "Urgência"]);

        /**
         * Inserir funções dos PSaude
         */
        DB::table('funcao')->insert(['nome' => "Médico"]);
        DB::table('funcao')->insert(['nome' => "Oftalmologista"]);
        DB::table('funcao')->insert(['nome' => "Farmacêutico"]);

        /**
         * inserir relação com paciente
         */
        DB::table('relacao_paciente')->insert(['nome' => "Pai"]);
        DB::table('relacao_paciente')->insert(['nome' => "Mãe"]);
        DB::table('relacao_paciente')->insert(['nome' => "Filho"]);
        DB::table('relacao_paciente')->insert(['nome' => "Cunhado"]);
        DB::table('relacao_paciente')->insert(['nome' => "Tio"]);
        DB::table('relacao_paciente')->insert(['nome' => "Avó"]);


    }
}
