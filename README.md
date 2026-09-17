# Docker med Spring boot, Docker hub & AWS ECR 

## Beskrivelse

* Dette repoet inneholder en veldig enkel Spring Boot applikasjon som sier "hello" når en request kommer til context root (/)
* I denne øvingen skal dere bli bedre kjent med Docker og hvordan vi lager et Docker container Image av en Spring boot applikasjon.
* Vi skal bli kjent med både Docker hub og AWS ECR
* Vi skal også sette opp en CI pipeline for å automatisk bygge et nytt container image på hver push til main branch.

## Lag en fork og et Codespace

* Dette begynner å bli kjent nå, right? 
* Du må start med å lage en fork av dette repoet til din egen GitHub konto. 

## Installer AWS CLI i ditt codespace 

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

# Lag container av en Spring Boot applikasjon og push til Docker hub

Docker er installert i ditt codespace. Verifiser of test

```docker run hello-world``` 

Forventet resultat  

```Unable to find image hello-world:latest locally
 Pulling repository hello-world
 91c95931e552: Download complete
 a8219747be10: Download complete
 Status: 
 Downloaded newer image for hello-world:latest
 Hello from Docker.
 This message shows that your installation appears to be working correctly.

 To generate this message, Docker took the following steps:
  1. The Docker Engine CLI client contacted the Docker Engine daemon.
  2. The Docker Engine daemon pulled the "hello-world" image from the Docker Hub.
     (Assuming it was not already locally available.)
  3. The Docker Engine daemon created a new container from that image which runs the
     executable that produces the output you are currently reading.
  4. The Docker Engine daemon streamed that output to the Docker Engine CLI client, which sent it
     to your terminal.

 To try something more ambitious, you can run an Ubuntu container with:
  $ docker run -it ubuntu bash

 For more examples and ideas, visit:
  https://docs.docker.com/userguide/

```

Kjør kommandoen 

```aidl
docker images
```
Du vil se at Docker har lastet ned et *hello-world* container image. 
Vi skal nå slette dette, men vi må først fjerne en stoppet container som er basert på dette imaget

Kjør først kommandoen ```docker ps``` for å se hvilke containere som kjører. Du vil få en tom liste

```aidl
docker ps
```

Legger du på -a argumentet, vil du også se stoppede containere  

```aidl
docker ps -a 
```

Du kan få output som for eksempel 

```aidl
CONTAINER ID   IMAGE         COMMAND    CREATED         STATUS                     PORTS     NAMES
5a89931c5af6   hello-world   "/hello"   2 minutes ago   Exited (0) 2 minutes ago             fervent_bell
```

Slett den stoppede containeren med 

```aidl
docker rm <container id> - i eksemplet over 5a89931c5af6
```

OBS, og til info; Docker-kommandoen docker rm brukes til å fjerne en eller flere stoppede containere. Kommandoen fjerner ikke kjørende containere; den fungerer kun på stoppede containere, men du kan overstyre dette med 

```
docker rm -f <container id> 
```

Kjør ```docker images``` igjen. Docker-kommandoen docker images rm brukes  til å slette et container image.
Du kan teste dette med;

```aidl
docker image rm <IMAGE ID>
```

# Docker Image

Først; Sjekk at du kan kjøre Spring Boot applikasjonen med Maven 
```
mvn spring-boot:run
```

* Sjekk at applikasjonen kjører. 
* Åpne en ny terminal i ditt cosepace og kjør  
```
curl localhost:8080                                                                                                            
```
Den skal bare svare "Hello" 

Nå skal vi lage en Dockerfile for Spring Boot-applikasjonen. Vi skal bruke en "multi stage" Docker fil, som 
først lager en container som har alle verktøy til å bygge applikasjonen, maven osv.

Spring boot applikasjonen blir kompilert og bygget i denne containeren.  Deretter bruker den resultatet fra byggeprosessen, JAR filen til å lage en runtime container for applikasjonen. 

Ta gjerne en pause og les gjerne mer om multi stage builds her; https://docs.docker.com/develop/develop-images/multistage-build/

Kopier dette innholder inn i en ny fil som skal hete  ```Dockerfile``` i rotkatalogen i ditt workspace

```dockerfile

# Build the Maven project using Java 17
FROM maven:3.8-eclipse-temurin-17 as builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn package

# Use a base image with Java 17
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar /app/application.jar
ENTRYPOINT ["java", "-jar", "/app/application.jar"]
```

Prøv å bygge en Docker container

```sh
docker build . --tag <du bestemmer tag eller navn>
```

Prøv å starte en container basert dette container image.  
```sh
docker run <tag eller navn som brukt over>
```

Når du starter en container, så lytter ikke applikasjonen på port 8080. Hvorfor ikke ? Hint; port mapping 

### Oppgave

Kan du start to versjoner av samme container, hvor en lytter på port 8080 og den andre på 8081?


## Registrer deg på Docker hub

https://hub.docker.com/signup

### Lag et security token på Docker hub

Du lager er token ved å trykke på ditt profilbilde (øverst til høyre) - og deretter "Account Settings", Personal Access tokens, og Generate Token. 

* Gi tokenet et navn og read/write/delete permissions.

## Logg innn - Bygg en container og push til Docker hub 

Login på Docker Hub fra terminalen din 
```
docker login -u <ditt brukernavn på dockerhub>
```

Når du kjørte `docker build` valgte du en `tag` denne trenger du nå...
```
docker tag <tag> <ditt brukernavn på dockerhub>/<tag>
docker push <ditt brukernavn på dockerhub>/<tag>
```

Eksempel:
```
docker login
docker tag fantasticapp glennbech/fantasticapp
docker push glennbech/fantasticapp
```

Gå til dockerhub.com og se på container image du nettopp lastet opp.

## Share the joy! 

Del gjerne Docker hub container image navnet med andre, så de kan forsøke å kjøre det med ```docker run``` mitt container image heter ```glennbech/shaky```

# Del 2 - Amazon Container Registry ECR

## Konfigurere AWS Access keys 

* Lag aksessnøkler https://github.com/glennbechdevops/aws-iam-accesskeys
* Kjør `aws configure` og oppgi Access Key ID, secret access Key, Region (eu-west-1) og json som filformat
  

## Lag et AWS  ECR repository for din container

* Pass på at du er i AWS region eu-west-1
* Du kan lage et ECR repository fra kommandlinje med `àws ecr ...` eller fra AWS Console. Du velger, men du må finne ut hvordan du gjør det selv. 

## Autentiser docker mot AWS ECR

Du kan gjøre dette ved å kjøre
```
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 244530008913.dkr.ecr.eu-west-1.amazonaws.com
````

Denne ser kanskje litt kryptisk ut, dette er hva som skjer steg for steg 

### aws ecr get-login-password --region eu-west-1

Denne delen av kommandoen bruker AWS CLI (aws) til å hente et midlertidig innloggingspassord for ECR (Elastic Container Registry).
get-login-password er en AWS-kommando som returnerer et passord som er nødvendig for å autentisere Docker mot ECR.
--region eu-west-1 spesifiserer hvilken region du vil hente passordet for. I dette tilfellet er regionen eu-west-1 (Vest-Europa, Irland).

### | docker login --username AWS --password-stdin 244530008913.dkr.ecr.eu-west-1.amazonaws.com 

* Symbolet | er en pipe som brukes til å sende output fra den første kommandoen (passordet) som input til den neste kommandoen.
*  docker login --username AWS --password-stdin 244530008913.dkr.ecr.eu-west-1.amazonaws.com er kommandoen for å logge inn på Docker, hvor --username AWS angir at brukernavnet er AWS.
--password-stdin gjør det mulig for Docker å lese passordet fra standard input (stdin), som i dette tilfellet kommer fra den første kommandoen via pipen.
* 244530008913.dkr.ecr.eu-west-1.amazonaws.com er URL-en til ECR-registeret du prøver å logge inn på.
* Dette spesifiserer nøyaktig hvilket ECR-register Docker skal autentisere mot.
    
##  Push et container image til dit ECR repository

Eksempel:
```sh
docker build -t <ditt tagnavn> .
docker tag <ditt tagnavn> 244530008913.dkr.ecr.eu-west-1.amazonaws.com/<ditt ECR repo navn>
docker push 244530008913.dkr.ecr.eu-west-1.amazonaws.com/<ditt ECR repo navn>
```

Gå til tjenesten ECR i AWS og se at du har fått et container image i ditt registry

## Få GitHub Actions til å bygge & pushe et nytt Image hver gang noen lager en ny commit på main branch 

For å lage github actions workflows lager du en fil under .github/workflows katalogen i repsoitory.

Her er et eksempel på en workflow tatt fra foreleser sitt miljø, du må gjøre endringer for å tilpasse den ditt eget? 
Lykke til!

NB. Du må først legge til Repository secrets for å gi GitHub "actions" AWS nøkler!

```yaml
name: Publish Docker image

on:
  push:
    branches:
      - main

jobs:
  push_to_registry:
    name: Push Docker image to ECR
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repo
        uses: actions/checkout@v2

      - name: Build and push Docker image
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 244530008913.dkr.ecr.eu-west-1.amazonaws.com
          rev=$(git rev-parse --short HEAD)
          docker build . -t hello
          docker tag hello 244530008913.dkr.ecr.eu-west-1.amazonaws.com/glenn:$rev
          docker push 244530008913.dkr.ecr.eu-west-1.amazonaws.com/glenn:$rev
```
Gjør endringer på koden i main branch - se at GitHub actions lager et nytt container image og laster opp til ECR. 

# Bonus challenge

* Kan du laste opp image til både AWS ECR, men også Docker Hub fra GitHub Actions workflowen?
* Kan du kjøre Spring boot applikasjonen din på tjenesten AWS Apprunner ? https://docs.aws.amazon.com/apprunner/latest/dg/what-is-apprunner.html
