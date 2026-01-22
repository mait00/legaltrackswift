import { Alert } from 'react-native';

export const ErrorsHelper = {
	showDefaultAlert: (title: string, subTitle: string) => {
		Alert.alert(title, subTitle);
	},
};
