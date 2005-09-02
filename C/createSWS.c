#include <stdio.h>
#include <stdlib.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils_WSRF.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int   lifetime;
  char  containerAddr[256];
  char  registryAddr[256];
  char  checkpointEPR[256];
  char  application[256];
  char  purpose[1024];
  char *username;
  char *group = "RSS";
  char *EPR;

  if(argc < 6){
    printf("Usage:\n  createSWS <address of container> <address of registry>"
	   " <lifetime (min)> <application> <purpose> [checkpoint EPR]\n");
    return 1;
  }

  strncpy(containerAddr, argv[1], 256);
  strncpy(registryAddr, argv[2], 256);
  sscanf(argv[3], "%d", &lifetime);
  strncpy(application, argv[4], 256);
  strncpy(purpose, argv[5], 1024);
  username = getenv("USER");

  checkpointEPR[0] = '\0';
  if(argc == 7){
    strncpy(checkpointEPR, argv[6], 256);
  }

  EPR = Create_SWS(lifetime, containerAddr, registryAddr,
		   username, group, application,
		   purpose, checkpointEPR);

  if(EPR){
    printf("Address of SWS = %s\n", EPR);
  }
  else{
    printf("FAILED to create SWS :-(\n");
  }
	 
  return 0;
}
