#include <stdio.h>
#include <time.h>
void hoge();
main(){
  int i,j;
  int times=1000;
  setbuf(stdout,NULL);
  printf("0%%       50%%       100%%\n");
  printf("+---------+---------+\n");
  for(i=0;i<times;i++){
  /* 適当な処理 */
    hoge();
    if(i%(times/20)==times/20-1){
  /* プログレスバーの表示 */
      for(j=0;j<(i+1)/(times/20)+1;j++)
        printf("#");
  /* キャリッジリターンを利用して先頭にカーソルを移動 */
      printf("\r");
    }
    #if 0x0
    if(i%(times/100)==times/100-1){
  /* ラインフィードを使ってカーソルを下へ持っていく、 */
  /* エスケープシーケンスでは表示されていない領域へは */
  /* カーソルを移動できないから                       */
      printf("\n");
  /* パーセンテージを表示する */
      printf("%3.1d %%\n",i/(times/100)+1);
  /* エスケープシーケンスをつかってカーソルを上に持っていく */
      printf("\x1b[2A");
    }
    #endif
  }
  /* 終了する前にカーソルを下に持っていく */
  //printf("\x1b[2B");
  printf("\n");
}
/*適当な処理をする関数、
いい表現方法が思い浮かばなかったんですんません*/
void hoge(){
  clock_t t;
  /* 時間待ち開始 */
  t = clock() + CLOCKS_PER_SEC/20;
  while(t>clock());
  /* 時間待ち終了 */
}