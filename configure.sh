while getopts u:h:d:k:s:c: flag
do
    case "${flag}" in
        u) username=${OPTARG};;
        h) host=${OPTARG};;
    esac
done

ssh $username@$host 'bash -s' < essentials.sh
echo "finished setting up essentials. VPS is rebooting. The script is sleeping 20 seconds."
sleep 20
ssh $username@$host 'bash -s' < postgres.sh
ssh $username@$host 'bash -s' < platform.sh
ssh $username@$host 'bash -s' < nginx.sh
ssh $username@$host 'bash -s' < odoo.sh
echo "finished setting up essentials. VPS is rebooting. The script is sleeping 20 seconds."
sleep 20
ssh $username@$host