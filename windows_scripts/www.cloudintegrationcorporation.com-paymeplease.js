import http from 'k6/http';
import { check, sleep } from 'k6';
import exec from 'k6/execution';
import { Counter } from 'k6/metrics';

// Custom metrics to track exactly WHY it fails
const Error429 = new Counter('errors_429_throttled');
const Error504 = new Counter('errors_504_timeout');
const Error500 = new Counter('errors_500_crash');

export const options = {
  // Adjusted for "Legacy Premium": Slower ramp-up to see exactly when it breaks
  stages: [
    { duration: '30s', target: 20 },  // Safe zone?
    { duration: '30s', target: 50 },  // Danger zone?
    { duration: '1m',  target: 100 }, // Breaking point
    { duration: '20s', target: 0 },   // Cooldown
  ],
  thresholds: {
    http_req_duration: ['p(95)<8000'], // Goal: 95% of requests under 8s
    http_req_failed: ['rate<0.10'],    // Goal: Less than 10% failure
  },
};

const urlPrefix = 'https://www.cloudintegrationcorporation.com/paymeplease-open-v003/SWJ1czR0bkd5cTNGWmZaS2VRbDNhOWdIMGI0dlA2RElDdW9LMUxzQ3JrTE9USGtJYmUreXdNbEl0U25jdzltR2J2VHM4RXAvd3ZYT2hXZmJsUFM4dGFHL1lFNFVpVERacmlCSFpUclFmekg0djh4S3VtL3VsTWFLbFhSd2xhM3RGdVRqVVZFNXJPTW9ITndGQjFVRmNySjRrQ0hxRzh2R2FPSzRuWFhKTDJ4eVkvVEpuQUMyZlppOUY1OXNqZ1FyY1pZZmVkTU5RSjZxbXV1cGFUcHd2MEZpNWRRWHNhbHZRUDFkVXc3Y2JHRXRxQTFZUmYvZnpnWGlhTmJQa3RTdkZxdDZkWHA0eUp5b1lKajFkQUNnOU5ocjh0ZXJaLzAxMlVNNG5FbTk5ZDNuQVZ2NXRVS3VFMTFPZ2c0Y2JVb2hXMHVIbnhuTjdFMmdZZnUxTjB6ejJ3PT0=/TUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFsM1hMYmluYmpBcDFaMmxKTDBMZw1kTkNhT1VFVC8xcml5bzAwVGdIQkhEZVZueTFVZVlqWkp6SVBQcDc2TkpoOWMrWXhsZFJzTld2TjdvTS9FTXJ0DWFXcDhNMHQ2azJ3THFzVjdjSDJYZDlzUlNDamhaUzZmdEZaY29YMjN2Y3VPdm81eld4YTFzQ0cvZEF2bHBoUWgNQTczZTlkSlV4NFhDRjlKK3JpN3FueVNBUDFTR29qaEk4UUx5Y1JmVjR4Y2pOZXlyUVFZaTBKY0I4ZE0xcUNVaw16RjdMY1EyQ1dsc0dZZjc4MUNOOHpHUnF6bVU1aGU0cmliTjRiMityZU9GcTVrOGJhVm4wRWJJb2duNEFKc3BUDW1xRTRwaFVkejNNYWtuNGRqWjFoVjRuZjVNYlBrRkw4QTI2ZW5pZWxPZWovVklmRVozeHFsQVFzSDZyOE0zVDcNRlFJREFRQUI=/3aa5550b7fe348b98d7b5741afc65534/';

// Base Time: 2025-12-18T15:52:00Z
const baseTime = new Date('2025-12-18T15:52:00Z').getTime();

export default function () {
  const iteration = exec.scenario.iterationInTest;
  
  // Dynamic URL Generation
  const newDate = new Date(baseTime + (iteration * 1000));
  const newDateStr = newDate.toISOString().split('.')[0] + 'Z';
  const fullUrl = urlPrefix + newDateStr;

  // Real User simulation: Add headers so Wix thinks we are a browser, not a bot
  const params = {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)',
    },
  };

  const res = http.get(fullUrl, params);

  // Check results
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
  });

  // Log specific failure types for deeper analysis
  if (!success) {
    if (res.status === 429) Error429.add(1);      // Throttling
    else if (res.status === 504) Error504.add(1); // Timeout (CPU overload)
    else if (res.status === 500) Error500.add(1); // Script crash
  }

  // Jitter: Sleep between 0.5s and 1.5s (Random) to prevent artificial "spiking"
  sleep(Math.random() * 1 + 0.5);
}