#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cjson/cJSON.h>
#include <curl/curl.h>
#include <sys/mount.h>
#include <libcryptsetup.h>
#include <unistd.h>

#define SENSOR_ID "{device_uuid}"
#define DISK_KEY_LEN 47
#define SAFE_KEY_LEN 214
#define KEY_LEN 33
#define PATH_LEN 1024
#define SIZE 11000
#define OTP_FILE "{otp_file}"
#define KEYS_FILE "{keys_file}"

/***** SafeKey v1.0.4 *******/
/***** i46 - Janine Son ****/
/***** 2024-10-29 **************************/
/******************************************************************************************
SafeKey sends the device UUID to i46 server and get back a disk key
SafeKey mounts the USB disk
SafeKey retrieves the key from the disk and send it to i46 server in order to open the keys files
SafeKey will receive three keys:
Key 1 - to open the storage
Key 2 - to keep on the disk for the next time
Key 3 - to encrypt the storage
SafeKey extract the top key from the storage
SafeKey encrypt the storage file (without the key that had been used) using key3
SafeKey provide the top key via the API

cJSON-1.7.18
sudo ldconfig /usr/local/lib
Run
gcc safekey.c -o safekey -lcjson -lcurl -lcryptsetup
******************************************************************************************/

char inp_array[SIZE][KEY_LEN];
void error(const char *msg) { perror(msg); exit(0); }

struct string {
  char *ptr;
  size_t len;
};

void init_string(struct string *s) {
  s->len = 0;
  s->ptr = malloc(s->len+1);
  if (s->ptr == NULL) {
    fprintf(stderr, "malloc() failed\n");
    exit(EXIT_FAILURE);
  }
  s->ptr[0] = '\0';
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, struct string *s)
{
  size_t new_len = s->len + size*nmemb;
  s->ptr = realloc(s->ptr, new_len+1);
  if (s->ptr == NULL) {
    fprintf(stderr, "realloc() failed\n");
    exit(EXIT_FAILURE);
  }
  memcpy(s->ptr+s->len, ptr, size*nmemb);
  s->ptr[new_len] = '\0';
  s->len = new_len;

  return size*nmemb;
}

void encrypt(char encryptionKey[KEY_LEN])
{
     char bufferEn[150];
     snprintf(bufferEn, sizeof(bufferEn), "echo %s | gpg --batch --yes --passphrase-fd 0 --symmetric {keys_file}", encryptionKey);
     system(bufferEn);
}
void decrypt(char storageKey[KEY_LEN])
{
     char buffer[200];
     snprintf(buffer, sizeof(buffer), "export GPG_TTY=$(tty) && echo %s | gpg --batch --yes --passphrase-fd 0 --output {keys_file} -d {keys_file_encrypted}", storageKey);
     system(buffer);
}

void pop()
{
     system("mkdir /var/lock/.pop.lock && head -n 1 {keys_file} | tee {otp_file} && sed -i '1d' {keys_file} && rmdir /var/lock/.pop.lock");
}

void getNewKey(cJSON *rootValidate, int isSuccess){
     char responseKey[KEY_LEN];
     if (isSuccess){
          cJSON *commandValidate = cJSON_GetObjectItem(rootValidate, "responseKey");
          strcpy (responseKey, commandValidate->valuestring);
     }

     cJSON *commandValidateStorage = cJSON_GetObjectItem(rootValidate, "storageKey");
     cJSON *commandValidateEncryption = cJSON_GetObjectItem(rootValidate, "encryptionKey");

     char storageKey[KEY_LEN];
     char encryptionKey[KEY_LEN];

     strcpy (storageKey, commandValidateStorage->valuestring);
     strcpy (encryptionKey, commandValidateEncryption->valuestring);
     cJSON_Delete(rootValidate);

     /* Decrypt storage using storageKey */
     printf("Decrypting file \n");

     /*system("echo storageKey | sudo gpg --no-symkey-cache -o {keys_file} --decrypt {keys_file_encrypted}");*/
     decrypt(storageKey);
     if (access("{keys_file}", F_OK) == 0) {
        remove("{keys_file_encrypted}");
     } else {
        printf("Decrypted file doesn't exist ...retrying...\n");
        decrypt(storageKey);
        if (access("{keys_file}", F_OK) == 0) {
            remove("{keys_file_encrypted}");
        } else{
           printf("Decrypted file doesn't exist\n");
        }
        exit(-1);
     }

      /* Pop topmost key. Put key inside otp.dat*/
     pop();

     printf("Top key popped\n");

     /* Encrypt storage using encryptionKey */
     printf("\nEncrypting file \n");
     /*system("echo encryptionKey | sudo gpg --passphrase-fd 0 --always-trust -r $USER --encrypt {keys_file}");*/
     encrypt(encryptionKey);
     if (access("{keys_file_encrypted}", F_OK) == 0) {
         remove("{keys_file}");
     } else {
         printf("Encrypted file doesn't exist \n");
        exit(-1);
     }

     FILE *fpNew = fopen(OTP_FILE, "ab+");
     char currentKeyNew[KEY_LEN];
     fgets(currentKeyNew, KEY_LEN, fpNew);

     if (isSuccess){
       if (strcmp(currentKeyNew, responseKey) == 0){
         printf("New current otp: %s\n\n", currentKeyNew);
       }else{
         printf("New current otp and response doesn't match. Something went wrong...\n");
         exit(-1);
       }
     }else{
        printf("New current otp (last key fixed): %s\n\n", currentKeyNew);
     }

     printf("Success \n");
}


int main()
{

    char url[PATH_LEN]="{server_protocol}://{server_host}:{server_port}";
    CURL *curl;
    CURLcode res;

    /* Retrieve one time key */
    FILE *fp = fopen(OTP_FILE, "ab+");
    char currentKey[KEY_LEN];
    fgets(currentKey, KEY_LEN, fp);

    printf("Current key: %s\n\n", currentKey);

    if (strlen(currentKey)<5){
       printf("OTP not found \n");
       return -1;
    }

    /* Send to i46 server to verify if key matches
    ** Get 3 keys in the response */
    char resourceValidate[PATH_LEN] = "/safekey/key/validate";
    char urlPost[PATH_LEN]="";

    strcat(urlPost, url);
    strcat(urlPost, resourceValidate);

    printf("Request [POST]:\n%s\n", urlPost);

    char responseValidate[PATH_LEN];
      /* get a curl handle */
      curl = curl_easy_init();
      if(curl) {
         struct string sValidate;
         init_string(&sValidate);

        /* First set the URL that is about to receive our POST. This URL can
           just as well be an https:// URL if that is what should receive the
           data. */
        curl_easy_setopt(curl, CURLOPT_INTERFACE, "{interface}");
        curl_easy_setopt(curl, CURLOPT_URL, urlPost);
        curl_easy_setopt(curl, CURLOPT_HTTPAUTH, (long)CURLAUTH_BASIC);
        curl_easy_setopt(curl, CURLOPT_USERNAME, "{user}");
        curl_easy_setopt(curl, CURLOPT_PASSWORD, "{password}");
        /*curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);*/
        /*curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);*/
        /* Now specify the POST data */

        char message_fmt[PATH_LEN] = "uuid={device_uuid}&key=";
        strcat(message_fmt, currentKey);

        printf("%s\n", message_fmt);

        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, message_fmt);

        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &sValidate);
        res = curl_easy_perform(curl);
        /* Check for errors */
        if (res != CURLE_OK)
            fprintf(stderr, "curl_easy_perform() failed: %s\n",curl_easy_strerror(res));

        strcpy(responseValidate,sValidate.ptr);
        free(sValidate.ptr);

        printf("Response:\n%s\n",responseValidate);

        /* always cleanup */
        curl_easy_cleanup(curl);
      }

    cJSON *rootValidate = cJSON_Parse(responseValidate);
    cJSON *command = cJSON_GetObjectItem(rootValidate, "responseKey");

    char *json_string = cJSON_Print(command);
    if (json_string)
    {
        if (json_string != NULL){
            getNewKey(rootValidate, 1);
        }else{
            printf("Invalid code\n");
            return -1;
        }
    }else{
        cJSON *commandFail = cJSON_GetObjectItem(rootValidate, "fail");
        char *json_string_fail = cJSON_Print(commandFail);

        if (json_string_fail)
        {
            printf("%s\n", json_string_fail);
            if (strstr(json_string_fail, "Last key") != NULL){
                  printf("Last key\n");
            }
            cJSON_free(json_string_fail);
        }
    }

    cJSON_free(json_string);
    return 0;
}
