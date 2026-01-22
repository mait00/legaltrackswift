import axios from 'axios';
import { BASE_URL } from './../../../constants';

class CommonAPI {
	getCode = (phone: string) => {
		return axios.get(BASE_URL + '/auth/get-auth-code?phone=' + phone);
	};

	sendCode = (phone: string, code: string) => {
		return axios.get(BASE_URL + '/auth/check-auth-code?phone=' + phone + '&code=' + code);
	};

	getProfile = () => {
		return axios.get(BASE_URL + '/auth/user-detail');
	};

	editProfile = (first_name: string, last_name: string, email: string, type: string) => {
		const params = JSON.stringify({
			first_name,
			last_name,
			email,
			type,
		});
		return axios.post(BASE_URL + '/auth/edit-profile', params, {
			'Content-Type': 'application/json',
		});
	};

	getNotifications = () => {
		return axios.get(BASE_URL + '/subs/get-notiffications');
	};

	getDelays = () => {
		return axios.get(BASE_URL + '/subs/get-delays');
	};

	getSubscribtions = () => {
		return axios.get(BASE_URL + '/subs/get-subscribtions');
	};

	getMessages = () => {
		return axios.get(BASE_URL + '/api/messages');
	};
}

const commonRequests = new CommonAPI();
export default commonRequests;
