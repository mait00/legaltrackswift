import AsyncStorage from '@react-native-async-storage/async-storage';

class StorageService {
	saveData = (name: string, data: string) => {
		return Promise.all([AsyncStorage.setItem(name, data)]);
	};

	getData = (name: string) => {
		return AsyncStorage.getItem(name);
	};

	removeAll = () => {
		return AsyncStorage.clear();
	};
}
const StorageHelper = new StorageService();
export default StorageHelper;
