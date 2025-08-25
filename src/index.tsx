import { render } from 'preact';

import './style.css';
import { App } from './App';

export function Index() {
	return (
		<App />
	);
}

render(<Index />, document.getElementById('app'));
