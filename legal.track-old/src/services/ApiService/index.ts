import axios, { AxiosError, AxiosRequestConfig } from 'axios';
import { BASE_URL } from './../../constants';
import { commonRequests } from './Requests';

export interface ApiResponse<T> {
	status: number;
	data: T;
	points: T;
	message: string;
}

axios.interceptors.request.use(
	async (config) => {
		console.warn('Request', config.headers);
		const newConfig: AxiosRequestConfig = {
			...config,
			baseURL: BASE_URL,
			headers: { ...config.headers, 'Content-Type': 'application/json' },
		};

		return newConfig;
	},
	(error: AxiosError) => {
		return Promise.reject(error);
	},
);

class APIService {
	common = commonRequests;

	setToken = (token: string) => {
		console.log('APIService -> setToken -> token', token);
		axios.defaults.headers['Authorization'] = token;
	};
}

const API = new APIService();
export default API;