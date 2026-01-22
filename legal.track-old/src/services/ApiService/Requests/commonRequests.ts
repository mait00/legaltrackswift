import axios from 'axios';
import { BASE_URL } from './../../../constants';

class CommonAPI {
	getCode = (phone: string) => {
		return axios.get(BASE_URL + '/auth/get-auth-code?phone=' + phone);
	};

	sendCode = (phone: string, code: string) => {
		console.warn(BASE_URL + '/auth/check-auth-code?phone=' + phone + '&code=' + code);
		return axios.get(BASE_URL + '/auth/check-auth-code?phone=' + phone + '&code=' + code);
	};

	getProfile = () => {
		return axios.get(BASE_URL + '/auth/user-detail');
	};

	getTarifs = () => {
		return axios.get(BASE_URL + '/api/user-tarif');
	};

	cancelTarif = () => {
		return axios.get(BASE_URL + '/api/user-cancel-subscribtion');
	};

	editProfile = (first_name: string, last_name: string, email: string, type: string) => {
		const params = JSON.stringify({
			first_name,
			last_name,
			email,
			type,
		});
		console.warn(params);
		return axios.post(BASE_URL + '/auth/edit-profile', params, {
			headers: {
				'Content-Type': 'application/json',
			}
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

	sendMessage = (text: any) => {
		const params = JSON.stringify({
			text,
		});
		return axios.post(BASE_URL + '/api/new-message', params);
	};

	setPushId = (uid: string) => {
		const params = JSON.stringify({
			uid,
		});
		return axios.post(BASE_URL + '/auth/edit-push-uid', params);
	};

	deleteSubscription = (id: number, type: string) => {
		console.warn(BASE_URL + '/subs/delete?id=' + id + '&type=' + type);
		return axios.get(BASE_URL + '/subs/delete?id=' + id + '&type=' + type);
	};

	renameCase = (id: number, name: string) => {
		const params = JSON.stringify({
			id,
			name,
		});
		return axios.post(BASE_URL + '/subs/rename-case', params);
	};

	renameCompany = (id: number, name: string) => {
		const params = JSON.stringify({
			id,
			name,
		});
		return axios.post(BASE_URL + '/subs/rename-company', params);
	};

	renameAudio = (id: number, name: string) => {
		const params = JSON.stringify({
			id,
			name,
		});
		console.warn(BASE_URL + '/subs/rename-audio');
		return axios.post(BASE_URL + '/subs/rename-audio', params);
	};

	validateReceipt = (receipt: string, store_type: string, tarif: string) => {
		const params = JSON.stringify({
			receipt,
			store_type,
			tarif,
		});
		return axios.post(BASE_URL + '/api/validate-receipt', params);
	};

	getCase = (id: number) => {
		return axios.get(BASE_URL + '/subs/detail-case?id=' + id);
	};

	getCompany = (id: number) => {
		return axios.get(BASE_URL + '/subs/detail-company?id=' + id);
	};

	getKeyword = (id: number) => {
		return axios.get(BASE_URL + '/subs/detail-keyword?id=' + id);
	};

	getCategoriesCases = () => {
		return axios.get(BASE_URL + '/subs/get-categories-cases');
	};

	getCourts = () => {
		return axios.get(BASE_URL + '/subs/get-courts');
	};

	getInstances = () => {
		return axios.get(BASE_URL + '/subs/get-instances');
	};

	getFaq = () => {
		return axios.get(BASE_URL + '/api/list-faq');
	};

	newSubscription = (type: string, value: string, sou: boolean) => {
		const params = JSON.stringify({
			type,
			value,
			sou,
		});
		console.warn('params: ', params);
		return axios.post(BASE_URL + '/subs/new-subscribtion', params);
	};

	editKeyword = (body: object) => {
		const params = JSON.stringify(body);
		return axios.post(BASE_URL + '/subs/edit-keyword', params);
	};

	mutePushCase = (id: number, mute_all: boolean) => {
		const params = JSON.stringify({
			id,
			mute_all,
		});
		return axios.post(BASE_URL + '/subs/mute-case-settings', params);
	};

	muteSidesCase = (id: number, muted_list) => {
		const params = JSON.stringify({
			id,
			muted_list,
		});
		return axios.post(BASE_URL + '/subs/mute-case-settings', params);
	};

	updateNote = (id: number, text: string) => {
		const params = JSON.stringify({
			id,
			text,
		});
		console.warn('updateNote', params);
		return axios.post(BASE_URL + '/subs/update-note', params);
	};

	addNote = (id: number, text: string) => {
		const params = JSON.stringify({
			id,
			text,
		});
		return axios.post(BASE_URL + '/subs/add-note', params);
	};

	searchCompanies = (query: string) => {
		const params = JSON.stringify({
			query,
		});
		return axios.post('https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/party', params, {
			headers: {
				'Authorization': 'Token cec00da4ce8539807a1ac56f2639ad1b873ca509',
				'Content-Type': 'application/json',
				"Accept": "application/json",
			}
		});
	};

	getCalendar = () => {
		return axios.get(BASE_URL + '/subs/get-calendar');
	};

	searchDelays = (query: string) => {
		return axios.get(BASE_URL + '/subs/search-delay?case_number=' + query);
	};

	uploadAudio = (id: number, file: any) => {
		var formData = new FormData();
		formData.append("id", id);
		// formData.append("file", {name: 'test.mp4', filename: 'test.mp4', type: 'audio/mp4', data: file});
		formData.append("file", {uri: file, name: 'test.mp4', type: 'audio/mp4'})
		// formData.append("file", file);
		return axios.post(BASE_URL + '/subs/upload-audio', formData, {
			headers: {
			  'Content-Type': 'multipart/form-data'
			}
		});
	};
}

const commonRequests = new CommonAPI();
export default commonRequests;
