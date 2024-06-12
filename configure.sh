while getopts u:h:d:k:s:c: flag
do
    case "${flag}" in
        u) username=${OPTARG};;
        h) host=${OPTARG};;
        d) ovh_domain=${OPTARG};;
        k) ovh_application_key=${OPTARG};;
        s) ovh_application_secret=${OPTARG};;
        c) ovh_consumer_key=${OPTARG};;
    esac
done

ssh $username@$host 'bash -s' < essentials.sh
echo "finished setting up essentials. VPS is rebooting. The script is sleeping 20 seconds."
sleep 20
ssh $username@$host 'bash -s' < platform.sh
ssh $username@$host 'bash -s' < nginx.sh $ovh_domain $ovh_application_key $ovh_application_secret $ovh_consumer_key